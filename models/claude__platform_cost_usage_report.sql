{{ config(enabled=var('claude__using_cost_report', True) and var('claude__using_message_usage_report', True) and var('claude__using_api_key', True)) }}

{% set token_columns = [
    ('uncached_input_token', 'input'),
    ('cache_read_input_token', 'cache_read'),
    ('cache_creation_ephemeral_5_m_input_token', 'cache_creation_5m'),
    ('cache_creation_ephemeral_1_h_input_token', 'cache_creation_1h'),
    ('output_token', 'output')
] %}

{% set using_workspace = var('claude__using_workspace', True) %}
{% set using_users = var('claude__using_users', True) %}

with cost_report as (

    select *
    from {{ ref('stg_claude__cost_report') }}
),

message_usage_report as (

    select *
    from {{ ref('stg_claude__message_usage_report') }}
),

api_key as (

    select *
    from {{ ref('int_claude__api_key') }}
),

-- One row per api key, date_day, model and token type. Service tier, context window and inference geo dropped
usage_unpivoted as (

    {% for column_name, token_unit_type in token_columns %}
    select
        source_relation,
        starting_date as date_day,
        workspace_id,
        api_key_id,
        model,
        '{{ token_unit_type }}' as token_unit_type,
        {{ column_name }} as unit_quantity

    from message_usage_report
    -- a zero-token row takes no cost allocation, and every message usage row would
    -- otherwise produce one row here per token type regardless of what it used
    where {{ column_name }} > 0
    {{ 'union all' if not loop.last }}
    {% endfor %}
),

-- Message usage does not always report a workspace, so fall back to the workspace recorded
-- on the api key itself.
usage as (

    select
        usage_unpivoted.source_relation,
        usage_unpivoted.date_day,
        coalesce(usage_unpivoted.workspace_id, api_key.workspace_id) as workspace_id,
        coalesce(usage_unpivoted.workspace_id, api_key.workspace_id, '__org__') as workspace_key, -- temporary
        usage_unpivoted.api_key_id,
        api_key.name as api_key_name,
        api_key.is_deleted as is_api_key_deleted,
        {% if using_users -%}
        api_key.is_creator_deleted,
        api_key.created_by_name,
        api_key.created_by_email,
        {% endif -%}
        {% if using_workspace -%}
        api_key.workspace_name,
        {% endif -%}
        usage_unpivoted.model,
        usage_unpivoted.token_unit_type,
        sum(usage_unpivoted.unit_quantity) as unit_quantity

    from usage_unpivoted
    left join api_key
        on usage_unpivoted.api_key_id = api_key.api_key_id
        and usage_unpivoted.source_relation = api_key.source_relation

    {{ dbt_utils.group_by(n=9 + (3 if using_users else 0) + (1 if using_workspace else 0)) }}
),

-- each api key's share of the workspace tokens of the same type that date_day
share_by_token_unit_type as (

    select
        usage.*,
        unit_quantity / nullif(sum(unit_quantity) over (
            partition by source_relation, date_day, workspace_key, model, token_unit_type
        ), 0) as token_share

    from usage
),

-- Web search cost is billed at a flat rate per request (about $0.01), so it is allocated on
-- actual web search requests rather than on tokens.
web_search_usage as (

    select
        message_usage_report.source_relation,
        message_usage_report.starting_date as date_day,
        coalesce(message_usage_report.workspace_id, api_key.workspace_id) as workspace_id,
        coalesce(coalesce(message_usage_report.workspace_id, api_key.workspace_id), '__org__') as workspace_key,
        message_usage_report.api_key_id,
        api_key.name as api_key_name,
        api_key.is_deleted as is_api_key_deleted,
        {% if using_users -%}
        api_key.is_creator_deleted,
        api_key.created_by_name,
        api_key.created_by_email,
        {% endif -%}
        {% if using_workspace -%}
        api_key.workspace_name,
        {% endif -%}
        sum(message_usage_report.server_tool_use_web_search_request) as web_search_requests

    from message_usage_report
    left join api_key
        on message_usage_report.api_key_id = api_key.api_key_id
        and message_usage_report.source_relation = api_key.source_relation

    where message_usage_report.server_tool_use_web_search_request > 0
    {{ dbt_utils.group_by(n=7 + (3 if using_users else 0) + (1 if using_workspace else 0)) }}
),

-- each api key's share of the workspace's web search requests that day
share_web_search as (

    select
        web_search_usage.*,
        web_search_requests / nullif(sum(web_search_requests) over (
            partition by source_relation, date_day, workspace_key
        ), 0) as request_share

    from web_search_usage
),

-- One row per workspace cost slice: source_relation, date_day, workspace, model, cost_type
-- and token_unit_type. This is the grain every allocation branch below joins back to.
cost as (

    select
        source_relation,
        starting_date as date_day,
        workspace_id,
        coalesce(workspace_id, '__org__') as workspace_key,
        model,
        cost_type,
        token_unit_type,
        max(currency) as currency, -- currently always USD
        sum(amount) as amount

    from cost_report
    {{ dbt_utils.group_by(n=7) }}
),

-- cost that names a token type is allocated on that token type's share
allocated_by_token_unit_type as (

    select
        cost.source_relation,
        cost.date_day,
        coalesce(cost.workspace_id, share_by_token_unit_type.workspace_id) as workspace_id,
        {% if using_workspace -%}
        share_by_token_unit_type.workspace_name,
        {% endif -%}
        share_by_token_unit_type.api_key_id,
        share_by_token_unit_type.api_key_name,
        share_by_token_unit_type.is_api_key_deleted,
        {% if using_users -%}
        share_by_token_unit_type.is_creator_deleted,
        share_by_token_unit_type.created_by_name,
        share_by_token_unit_type.created_by_email,
        {% endif -%}
        cost.model,
        cost.cost_type,
        cost.token_unit_type,
        share_by_token_unit_type.unit_quantity,
        share_by_token_unit_type.token_share,
        cost.amount * share_by_token_unit_type.token_share as claude_cost,
        cost.currency,
        'token_share' as allocation_method

    from cost
    join share_by_token_unit_type
        on cost.source_relation = share_by_token_unit_type.source_relation
        and cost.date_day = share_by_token_unit_type.date_day
        and cost.workspace_key = share_by_token_unit_type.workspace_key
        and cost.model = share_by_token_unit_type.model
        and cost.token_unit_type = share_by_token_unit_type.token_unit_type

    where cost.cost_type = 'tokens'
),

-- Web search cost names no model, so unlike the other branches this does not join on one.
allocated_web_search as (

    select
        cost.source_relation,
        cost.date_day,
        coalesce(cost.workspace_id, share_web_search.workspace_id) as workspace_id,
        {% if using_workspace -%}
        share_web_search.workspace_name,
        {% endif -%}
        share_web_search.api_key_id,
        share_web_search.api_key_name,
        share_web_search.is_api_key_deleted,
        {% if using_users -%}
        share_web_search.is_creator_deleted,
        share_web_search.created_by_name,
        share_web_search.created_by_email,
        {% endif -%}
        cost.model,
        cost.cost_type,
        cost.token_unit_type,
        cast(null as {{ dbt.type_int() }}) as unit_quantity,
        share_web_search.request_share as token_share,
        cost.amount * share_web_search.request_share as claude_cost,
        cost.currency,
        'web_search_request_share' as allocation_method

    from cost
    join share_web_search
        on cost.source_relation = share_web_search.source_relation
        and cost.date_day = share_web_search.date_day
        and cost.workspace_key = share_web_search.workspace_key

    where cost.cost_type = 'web_search'
),

allocated as (

    select * from allocated_by_token_unit_type
    union all
    select * from allocated_web_search
),

-- Cost no api key could be attributed to, because the workspace reported no matching tokens
-- that date_day. Kept so claude_cost still ties out to the source cost report.
allocated_by_slice as (

    select
        source_relation,
        date_day,
        coalesce(workspace_id, '__org__') as workspace_key,
        model,
        cost_type,
        token_unit_type,
        sum(claude_cost) as allocated_cost

    from allocated
    group by 1, 2, 3, 4, 5, 6
),

unallocated as (

    select
        cost.source_relation,
        cost.date_day,
        cost.workspace_id,
        {% if using_workspace -%}
        cast(null as {{ dbt.type_string() }}) as workspace_name,
        {% endif -%}
        cast(null as {{ dbt.type_string() }}) as api_key_id,
        cast(null as {{ dbt.type_string() }}) as api_key_name,
        cast(null as {{ dbt.type_boolean() }}) as is_api_key_deleted,
        {% if using_users -%}
        cast(null as {{ dbt.type_boolean() }}) as is_creator_deleted,
        cast(null as {{ dbt.type_string() }}) as created_by_name,
        cast(null as {{ dbt.type_string() }}) as created_by_email,
        {% endif -%}
        cost.model,
        cost.cost_type,
        cost.token_unit_type,
        cast(null as {{ dbt.type_int() }}) as unit_quantity,
        cast(null as {{ dbt.type_float() }}) as token_share,
        cost.amount - coalesce(allocated_by_slice.allocated_cost, 0) as claude_cost,
        cost.currency,
        'unallocated' as allocation_method

    -- model and token_unit_type are null on non-token cost (web search, session usage), and
    -- null = null is never true, so those two columns need a null-safe comparison or every
    -- such slice would join to nothing and get double-counted as unallocated
    from cost
    left join allocated_by_slice
        on cost.source_relation = allocated_by_slice.source_relation
        and cost.date_day = allocated_by_slice.date_day
        and cost.workspace_key = allocated_by_slice.workspace_key
        and cost.model is not distinct from allocated_by_slice.model
        and cost.cost_type = allocated_by_slice.cost_type
        and cost.token_unit_type is not distinct from allocated_by_slice.token_unit_type

    where abs(cost.amount - coalesce(allocated_by_slice.allocated_cost, 0)) > 0.000001
),

union_allocations as (

    select * from allocated
    union all
    select * from unallocated
),

final as (

    select
        source_relation,
        date_day,
        workspace_id,
        {% if using_workspace -%}
        workspace_name,
        {% endif -%}
        api_key_id,
        api_key_name,
        is_api_key_deleted,
        {% if using_users -%}
        is_creator_deleted,
        created_by_name,
        created_by_email,
        {% endif -%}
        model,
        {{ claude.claude_model_family('model') }} as model_family,
        {{ claude.claude_model_variant('model') }} as model_variant,
        cost_type,
        token_unit_type,
        unit_quantity,
        token_share,
        claude_cost,
        currency,
        allocation_method

    from union_allocations
)

select *
from final
where coalesce(claude_cost, 0) != 0
   or coalesce(unit_quantity, 0) != 0
