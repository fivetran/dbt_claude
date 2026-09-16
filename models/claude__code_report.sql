with claude_code_usage_report as (

    select *
    from {{ ref('stg_claude__claude_code_usage_report') }}
),

model_breakdown as (

    select
        *,
        {{ claude.claude_model_family('model') }} as model_family,
        {{ claude.claude_model_variant('model') }} as model_variant
    from {{ ref('stg_claude__claude_code_usage_report_model_breakdown') }}
),

users as (

    select *
    from {{ ref('stg_claude__users') }}
),

{% if var('claude__using_organization', True) %}
organization as (

    select *
    from {{ ref('stg_claude__organization') }}
),
{% endif %}

-- Per-model token and cost detail is reported for only about 1% of usage report rows, so it
-- is rolled up onto the parent rather than fanned out into per-model rows -- otherwise almost
-- every row in this model would carry a null model.
breakdown_rollup as (

    select
        source_relation,
        claude_code_usage_report_fivetran_id,
        count(distinct model) as count_models_used,
        count(distinct model_family) as count_model_families_used,
        count(distinct model_variant) as count_model_variants_used,
        max(estimated_cost_currency) as estimated_cost_currency,
        sum(estimated_cost_amount) as estimated_cost, -- fractional cents
        sum(tokens_input) as tokens_input,
        sum(tokens_output) as tokens_output,
        sum(tokens_cache_creation) as tokens_cache_creation,
        sum(tokens_cache_read) as tokens_cache_read

    from model_breakdown
    {{ dbt_utils.group_by(n=2) }}
),

final as (

    select
        claude_code_usage_report.source_relation,
        claude_code_usage_report.claude_code_usage_report_id,
        claude_code_usage_report.report_date,
        claude_code_usage_report.organization_id,
        {% if var('claude__using_organization', True) %}
        organization.name as organization_name,
        {% endif %}
        claude_code_usage_report.customer_type,

        -- an actor is either a person, identified by email, or an api key, identified by name
        claude_code_usage_report.actor_type,
        claude_code_usage_report.actor_email_address,
        claude_code_usage_report.actor_api_key_name,
        users.user_id as user_id,
        users.name as user_name,
        users.role as user_role,
        users.is_deleted as is_user_deleted,

        claude_code_usage_report.terminal_type,

        -- core Claude Code activity
        claude_code_usage_report.sessions as count_sessions,
        claude_code_usage_report.commits_by_claude_code as count_commits,
        claude_code_usage_report.pull_requests_by_claude_code as count_pull_requests,
        claude_code_usage_report.lines_of_code_added as count_lines_of_code_added,
        claude_code_usage_report.lines_of_code_removed as count_lines_of_code_removed,

        -- per-model rollup, null on the rows that report no model breakdown
        breakdown_rollup.count_models_used,
        breakdown_rollup.count_model_families_used,
        breakdown_rollup.count_model_variants_used,
        breakdown_rollup.tokens_input,
        breakdown_rollup.tokens_output,
        breakdown_rollup.tokens_cache_creation,
        breakdown_rollup.tokens_cache_read,
        coalesce(breakdown_rollup.tokens_input, 0)
            + coalesce(breakdown_rollup.tokens_output, 0)
            + coalesce(breakdown_rollup.tokens_cache_creation, 0)
            + coalesce(breakdown_rollup.tokens_cache_read, 0) as total_tokens,
        breakdown_rollup.estimated_cost,
        breakdown_rollup.estimated_cost_currency

    from claude_code_usage_report

    left join breakdown_rollup
        on claude_code_usage_report.claude_code_usage_report_id
            = breakdown_rollup.claude_code_usage_report_fivetran_id
        and claude_code_usage_report.source_relation = breakdown_rollup.source_relation

    -- only user actors carry an email, so api key rows simply find no actor
    left join users
        on claude_code_usage_report.actor_email_address = users.email
        and claude_code_usage_report.source_relation = users.source_relation

    {% if var('claude__using_organization', True) %}
    left join organization
        on claude_code_usage_report.organization_id = organization.organization_id
        and claude_code_usage_report.source_relation = organization.source_relation
    {% endif %}
)

select *
from final
