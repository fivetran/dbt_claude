{{ config(enabled=var('claude_using_enterprise_user_activity', True)) }}

with base as (

    select *
    from {{ ref('stg_claude__enterprise_user_activity_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__enterprise_user_activity_tmp')),
                staging_columns=get_enterprise_user_activity_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        cast(date as date) as activity_date,
        user_id,
        chat_metrics_distinct_conversation_count,
        chat_metrics_message_count,
        claude_code_metrics_core_metrics_commit_count,
        claude_code_metrics_core_metrics_distinct_session_count,
        claude_code_metrics_core_metrics_lines_of_code_added_count,
        claude_code_metrics_core_metrics_lines_of_code_removed_count,
        claude_code_metrics_core_metrics_pull_request_count,
        cowork_metrics_distinct_session_count,
        cowork_metrics_message_count,
        design_metrics_distinct_session_count,
        design_metrics_message_count,
        office_metrics_excel_distinct_session_count,
        office_metrics_excel_message_count,
        office_metrics_outlook_distinct_session_count,
        office_metrics_outlook_message_count,
        office_metrics_powerpoint_distinct_session_count,
        office_metrics_powerpoint_message_count,
        office_metrics_word_distinct_session_count,
        office_metrics_word_message_count,
        web_search_count,
        _fivetran_synced

        {{ fivetran_utils.fill_pass_through_columns('claude__enterprise_user_activity_pass_through_metrics') }}

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
