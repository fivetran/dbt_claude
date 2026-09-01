{% set token_columns = [
    ('uncached_input_token', 'input'),
    ('cache_read_input_token', 'cache_read'),
    ('cache_creation_ephemeral_5_m_input_token', 'cache_creation_5m'),
    ('cache_creation_ephemeral_1_h_input_token', 'cache_creation_1h'),
    ('output_token', 'output')
] %}

with enterprise_user_cost_report as (

    select *
    from {{ ref('stg_claude__enterprise_user_cost_report') }}
),

enterprise_user_usage_report as (

    select *
    from {{ ref('stg_claude__enterprise_user_usage_report') }}
),

enterprise_user_actor as (

    select *
    from {{ ref('stg_claude__enterprise_user_actor') }}
),

-- One row per actor, day, product, model and token type. Speed, context window and inference
-- geo are summed away so both sides share a grain.
usage_long as (

    {% for column_name, unit_type in token_columns %}
    select
        source_relation,
        starting_date as day,
        actor_user_id,
        product,
        model,
        '{{ unit_type }}' as unit_type,
        {{ column_name }} as unit_quantity

    from enterprise_user_usage_report
    where coalesce({{ column_name }}, 0) > 0
    {{ 'union all' if not loop.last }}
    {% endfor %}
),

usage as (

    select
        source_relation,
        day,
        actor_user_id,
        product,
        model,
        unit_type,
        sum(unit_quantity) as unit_quantity

    from usage_long
    {{ dbt_utils.group_by(n=6) }}
),

-- The Analytics API reports per-user cost directly, so cost drives the grain and usage is
-- attached to it. cost_type is part of the grain because only token cost carries a unit_type.
cost as (

    select
        source_relation,
        starting_date as day,
        actor_user_id,
        product,
        model,
        cost_type,
        unit_type,
        max(currency) as currency,
        max(data_refreshed_at) as data_refreshed_at,
        sum(amount) as claude_cost,
        sum(list_amount) as claude_list_cost

    from enterprise_user_cost_report
    {{ dbt_utils.group_by(n=7) }}
),

cost_with_usage as (

    select
        cost.source_relation,
        cost.day,
        cost.actor_user_id,
        cost.product,
        cost.model,
        cost.cost_type,
        cost.unit_type,
        usage.unit_quantity,
        cost.claude_cost,
        cost.claude_list_cost,
        cost.currency,
        cost.data_refreshed_at

    from cost
    left join usage
        on cost.source_relation = usage.source_relation
        and cost.day = usage.day
        and cost.actor_user_id = usage.actor_user_id
        and cost.product = usage.product
        and cost.model = usage.model
        and cost.unit_type = usage.unit_type
),

-- usage an actor reported that carries no matching cost row, kept so no tokens are dropped
usage_without_cost as (

    select
        usage.source_relation,
        usage.day,
        usage.actor_user_id,
        usage.product,
        usage.model,
        cast(null as {{ dbt.type_string() }}) as cost_type,
        usage.unit_type,
        usage.unit_quantity,
        cast(null as {{ dbt.type_float() }}) as claude_cost,
        cast(null as {{ dbt.type_float() }}) as claude_list_cost,
        cast(null as {{ dbt.type_string() }}) as currency,
        cast(null as {{ dbt.type_timestamp() }}) as data_refreshed_at

    from usage
    left join cost
        on usage.source_relation = cost.source_relation
        and usage.day = cost.day
        and usage.actor_user_id = cost.actor_user_id
        and usage.product = cost.product
        and usage.model = cost.model
        and usage.unit_type = cost.unit_type

    where cost.actor_user_id is null
),

combined as (

    select * from cost_with_usage
    union all
    select * from usage_without_cost
),

final as (

    select
        combined.source_relation,
        combined.day,
        combined.actor_user_id,
        enterprise_user_actor.email as actor_email,
        enterprise_user_actor.name as actor_name,
        enterprise_user_actor.is_deleted as is_actor_deleted,
        combined.product,
        combined.model,
        combined.cost_type,
        combined.unit_type,
        combined.unit_quantity,
        combined.claude_cost,
        combined.claude_list_cost,
        combined.claude_list_cost - combined.claude_cost as claude_discount,
        combined.currency,
        combined.data_refreshed_at

    from combined
    left join enterprise_user_actor
        on combined.actor_user_id = enterprise_user_actor.actor_id
        and combined.source_relation = enterprise_user_actor.source_relation
)

select *
from final
where coalesce(claude_cost, 0) != 0
   or coalesce(unit_quantity, 0) != 0
