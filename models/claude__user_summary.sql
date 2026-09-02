{#- dbt-bigquery renders date_trunc as timestamp_trunc(cast(... as timestamp)), which returns a
   TIMESTAMP. The date columns compared against it are DATE, and BigQuery will not compare the
   two, so pin the result to a date. -#}
{%- set month_start = 'cast(' ~ dbt.date_trunc('month', 'current_date') ~ ' as date)' -%}

{% set cost_metrics = [
    ('claude_cost', 'claude_cost'),
    ('claude_list_cost', 'claude_list_cost'),
    ('tokens', 'unit_quantity')
] %}

{% set activity_metrics = [
    ('claude_code_sessions', 'claude_code_metrics_core_metrics_distinct_session_count'),
    ('claude_code_commits', 'claude_code_metrics_core_metrics_commit_count'),
    ('claude_code_pull_requests', 'claude_code_metrics_core_metrics_pull_request_count'),
    ('lines_of_code_added', 'claude_code_metrics_core_metrics_lines_of_code_added_count'),
    ('lines_of_code_removed', 'claude_code_metrics_core_metrics_lines_of_code_removed_count'),
    ('chat_messages', 'chat_metrics_message_count'),
    ('chat_conversations', 'chat_metrics_distinct_conversation_count'),
    ('cowork_messages', 'cowork_metrics_message_count'),
    ('web_searches', 'web_search_count')
] %}

with enterprise_user_actor as (

    select *
    from {{ ref('stg_claude__enterprise_user_actor') }}
),

users as (

    select *
    from {{ ref('stg_claude__users') }}
),

enterprise_report as (

    select *
    from {{ ref('claude__enterprise_user_report') }}
),

enterprise_user_activity as (

    select *
    from {{ ref('stg_claude__enterprise_user_activity') }}
),

-- Cost and tokens per actor, all time and for the current calendar month. Both windows are
-- rolled up in one pass with conditional aggregation rather than joining two summaries.
cost_rollup as (

    select
        source_relation,
        actor_user_id,
        {% for alias, column_name in cost_metrics -%}
        sum({{ column_name }}) as lifetime_{{ alias }},
        sum(case when date_day >= {{ month_start }} then {{ column_name }} end) as month_to_date_{{ alias }},
        {% endfor -%}
        count(distinct date_day) as lifetime_billed_days,
        count(distinct case when date_day >= {{ month_start }} then date_day end) as month_to_date_billed_days,
        min(date_day) as first_billed_date,
        max(date_day) as last_billed_date

    from enterprise_report
    {{ dbt_utils.group_by(n=2) }}
),

-- Claude Code, chat, Cowork and web search activity per actor, same two windows.
activity_rollup as (

    select
        source_relation,
        user_id as actor_user_id,
        {% for alias, column_name in activity_metrics -%}
        sum({{ column_name }}) as lifetime_{{ alias }},
        sum(case when activity_date >= {{ month_start }} then {{ column_name }} end) as month_to_date_{{ alias }},
        {% endfor -%}
        count(distinct activity_date) as lifetime_active_days,
        count(distinct case when activity_date >= {{ month_start }} then activity_date end) as month_to_date_active_days,
        min(activity_date) as first_active_date,
        max(activity_date) as last_active_date

    from enterprise_user_activity
    {{ dbt_utils.group_by(n=2) }}
),

final as (

    select
        enterprise_user_actor.source_relation,
        enterprise_user_actor.actor_id as actor_user_id,
        enterprise_user_actor.email,
        coalesce(enterprise_user_actor.name, users.name) as name,
        enterprise_user_actor.is_deleted as is_actor_deleted,

        -- role information, present only for actors that also appear as workspace users
        users.user_id,
        users.role,
        users.added_at as joined_organization_at,
        users.user_id is not null as is_workspace_user,

        -- cost and usage
        {% for alias, column_name in cost_metrics -%}
        cost_rollup.lifetime_{{ alias }},
        cost_rollup.month_to_date_{{ alias }},
        {% endfor -%}
        cost_rollup.lifetime_billed_days,
        cost_rollup.month_to_date_billed_days,
        cost_rollup.first_billed_date,
        cost_rollup.last_billed_date,
        cost_rollup.lifetime_claude_list_cost - cost_rollup.lifetime_claude_cost as lifetime_claude_discount,

        -- activity
        {% for alias, column_name in activity_metrics -%}
        activity_rollup.lifetime_{{ alias }},
        activity_rollup.month_to_date_{{ alias }},
        {% endfor -%}
        activity_rollup.lifetime_active_days,
        activity_rollup.month_to_date_active_days,
        activity_rollup.first_active_date,
        activity_rollup.last_active_date

    from enterprise_user_actor

    -- users.email is unique, so this cannot fan out. Only about half of actors have a users
    -- row, so role is null for the rest (offboarded people and non-user API actors).
    left join users
        on lower(enterprise_user_actor.email) = lower(users.email)
        and enterprise_user_actor.source_relation = users.source_relation

    left join cost_rollup
        on enterprise_user_actor.actor_id = cost_rollup.actor_user_id
        and enterprise_user_actor.source_relation = cost_rollup.source_relation

    left join activity_rollup
        on enterprise_user_actor.actor_id = activity_rollup.actor_user_id
        and enterprise_user_actor.source_relation = activity_rollup.source_relation
)

select *
from final
