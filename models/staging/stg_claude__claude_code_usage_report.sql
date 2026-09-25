{{ config(enabled=var('claude_using_claude_code_usage_report', True)) }}

with base as (

    select *
    from {{ ref('stg_claude__claude_code_usage_report_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__claude_code_usage_report_tmp')),
                staging_columns=get_claude_code_usage_report_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        _fivetran_id as claude_code_usage_report_id,
        organization_id,
        customer_type,
        cast(date as date) as report_date,
        terminal_type,
        lower(actor_type) as actor_type,
        actor_api_key_name,
        lower(actor_email_address) as actor_email_address,
        coalesce(core_metrics_pull_requests_by_claude_code, 0) as pull_requests_by_claude_code,
        coalesce(core_metrics_lines_of_code_removed, 0) as lines_of_code_removed,
        coalesce(core_metrics_lines_of_code_added, 0) as lines_of_code_added,
        coalesce(core_metrics_commits_by_claude_code, 0) as commits_by_claude_code,
        coalesce(core_metrics_num_sessions, 0) as sessions,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
