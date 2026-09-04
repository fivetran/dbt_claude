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
    ('cowork_sessions', 'cowork_metrics_distinct_session_count'),
    ('design_messages', 'design_metrics_message_count'),
    ('design_sessions', 'design_metrics_distinct_session_count'),
    ('office_messages', 'office_metrics_word_message_count + office_metrics_excel_message_count + office_metrics_outlook_message_count + office_metrics_powerpoint_message_count'),
    ('office_sessions', 'office_metrics_word_distinct_session_count + office_metrics_excel_distinct_session_count + office_metrics_outlook_distinct_session_count + office_metrics_powerpoint_distinct_session_count'),
    ('web_searches', 'web_search_count')
] %}

{# Additional numeric activity metrics passed through from enterprise_user_activity are summed the same way as the defaults above. #}
{% for field in var('claude__enterprise_user_activity_pass_through_metrics', []) %}
    {% if field is mapping %}
        {% set field_name = field.alias if field.alias else field.name %}
    {% else %}
        {% set field_name = field %}
    {% endif %}
    {% do activity_metrics.append((field_name, field_name)) %}
{% endfor %}

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
    from {{ ref('claude__enterprise_cost_usage_report') }}
),

enterprise_user_activity as (

    select *
    from {{ ref('stg_claude__enterprise_user_activity') }}
),

{% if var('claude__using_workspace_member', True) %}
workspace_member as (

    select *
    from {{ ref('stg_claude__workspace_member') }}
),
{% endif %}

{% if var('claude__using_workspace', True) %}
workspace as (

    select *
    from {{ ref('stg_claude__workspace') }}
),
{% endif %}

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
        sum(coalesce({{ column_name }}, 0)) as lifetime_{{ alias }},
        sum(case when activity_date >= {{ month_start }} then coalesce({{ column_name }}, 0) end) as month_to_date_{{ alias }},
        {% endfor -%}
        count(distinct activity_date) as lifetime_active_days,
        count(distinct case when activity_date >= {{ month_start }} then activity_date end) as month_to_date_active_days,
        min(activity_date) as first_active_date,
        max(activity_date) as last_active_date

    from enterprise_user_activity
    {{ dbt_utils.group_by(n=2) }}
),

{% if var('claude__using_workspace_member', True) %}
-- Workspace membership for the workspace user matched above. A user can belong to more
-- than one workspace, so this is rolled up to one row per user before it is joined onto the
-- actor grain below, and never joins workspace_member directly to enterprise_user_actor.
workspace_rollup as (

    select
        workspace_member.source_relation,
        workspace_member.user_id,
        count(distinct workspace_member.workspace_id) as count_workspaces,
        {% if var('claude__using_workspace', True) -%}
        {{ fivetran_utils.string_agg('distinct workspace.name', "', '") }} as workspace_names,
        {% endif -%}
        max(case when workspace_member.workspace_role = 'workspace_admin' then 1 else 0 end) = 1
            as is_workspace_admin,
        max(case when workspace_member.workspace_role in ('workspace_developer', 'workspace_restricted_developer') then 1 else 0 end) = 1
            as is_workspace_developer
    from workspace_member
    {% if var('claude__using_workspace', True) -%}
    left join workspace
        on workspace_member.workspace_id = workspace.workspace_id
        and workspace_member.source_relation = workspace.source_relation
    {%- endif %}

    {{ dbt_utils.group_by(n=2) }}
),
{% endif %}

final as (

    select
        enterprise_user_actor.source_relation,
        enterprise_user_actor.actor_user_id as user_id,
        users.user_id as workspace_user_id,
        coalesce(enterprise_user_actor.email, users.email) as email,
        coalesce(enterprise_user_actor.name, users.name) as name,
        coalesce(enterprise_user_actor.is_deleted, false) or coalesce(users.is_deleted, false) as is_user_deleted,

        -- role information, present only for actors that also appear as workspace users
        users.role,
        users.added_at as joined_organization_at,

        -- workspace membership, present only for actors with a matching workspace user
        {% if var('claude__using_workspace_member', True) -%}
        workspace_rollup.count_workspaces,
        {% if var('claude__using_workspace', True) -%}
        workspace_rollup.workspace_names,
        {% endif -%}
        workspace_rollup.is_workspace_admin,
        workspace_rollup.is_workspace_developer,
        {% endif -%}

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

    left join users
        on enterprise_user_actor.email = users.email
        and enterprise_user_actor.source_relation = users.source_relation

    left join cost_rollup
        on enterprise_user_actor.actor_user_id = cost_rollup.actor_user_id
        and enterprise_user_actor.source_relation = cost_rollup.source_relation

    left join activity_rollup
        on enterprise_user_actor.actor_user_id = activity_rollup.actor_user_id
        and enterprise_user_actor.source_relation = activity_rollup.source_relation

    {% if var('claude__using_workspace_member', True) -%}
    left join workspace_rollup
        on enterprise_user_actor.actor_user_id = workspace_rollup.user_id
        and enterprise_user_actor.source_relation = workspace_rollup.source_relation
    {%- endif %}
)

select *
from final
