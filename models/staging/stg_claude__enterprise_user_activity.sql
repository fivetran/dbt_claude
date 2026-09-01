
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
        chat_metrics_connectors_used_count,
        chat_metrics_distinct_artifacts_created_count,
        chat_metrics_distinct_conversation_count,
        chat_metrics_distinct_files_uploaded_count,
        chat_metrics_distinct_projects_created_count,
        chat_metrics_distinct_projects_used_count,
        chat_metrics_distinct_shared_artifacts_viewed_count,
        chat_metrics_distinct_skills_used_count,
        chat_metrics_message_count,
        chat_metrics_shared_conversations_viewed_count,
        chat_metrics_thinking_message_count,
        claude_code_metrics_core_metrics_commit_count,
        claude_code_metrics_core_metrics_distinct_session_count,
        claude_code_metrics_core_metrics_lines_of_code_added_count,
        claude_code_metrics_core_metrics_lines_of_code_removed_count,
        claude_code_metrics_core_metrics_pull_request_count,
        claude_code_metrics_tool_actions_edit_tool_accepted_count,
        claude_code_metrics_tool_actions_edit_tool_rejected_count,
        claude_code_metrics_tool_actions_multi_edit_tool_accepted_count,
        claude_code_metrics_tool_actions_multi_edit_tool_rejected_count,
        claude_code_metrics_tool_actions_notebook_edit_tool_accepted_count,
        claude_code_metrics_tool_actions_notebook_edit_tool_rejected_count,
        claude_code_metrics_tool_actions_write_tool_accepted_count,
        claude_code_metrics_tool_actions_write_tool_rejected_count,
        cowork_metrics_action_count,
        cowork_metrics_connectors_used_count,
        cowork_metrics_dispatch_turn_count,
        cowork_metrics_distinct_connectors_used_count,
        cowork_metrics_distinct_session_count,
        cowork_metrics_distinct_skills_used_count,
        cowork_metrics_message_count,
        cowork_metrics_skills_used_count,
        design_metrics_distinct_projects_created_count,
        design_metrics_distinct_projects_used_count,
        design_metrics_distinct_session_count,
        design_metrics_message_count,
        office_metrics_excel_connectors_used_count,
        office_metrics_excel_distinct_connectors_used_count,
        office_metrics_excel_distinct_session_count,
        office_metrics_excel_distinct_skills_used_count,
        office_metrics_excel_message_count,
        office_metrics_excel_skills_used_count,
        office_metrics_outlook_connectors_used_count,
        office_metrics_outlook_distinct_connectors_used_count,
        office_metrics_outlook_distinct_session_count,
        office_metrics_outlook_distinct_skills_used_count,
        office_metrics_outlook_message_count,
        office_metrics_outlook_skills_used_count,
        office_metrics_powerpoint_connectors_used_count,
        office_metrics_powerpoint_distinct_connectors_used_count,
        office_metrics_powerpoint_distinct_session_count,
        office_metrics_powerpoint_distinct_skills_used_count,
        office_metrics_powerpoint_message_count,
        office_metrics_powerpoint_skills_used_count,
        office_metrics_word_connectors_used_count,
        office_metrics_word_distinct_connectors_used_count,
        office_metrics_word_distinct_session_count,
        office_metrics_word_distinct_skills_used_count,
        office_metrics_word_message_count,
        office_metrics_word_skills_used_count,
        web_search_count,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
