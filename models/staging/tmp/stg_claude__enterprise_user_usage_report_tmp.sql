{{ config(enabled=var('claude_using_enterprise_user_usage_report', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='claude_sources',
        single_source_name='claude',
        single_table_name='enterprise_user_usage_report'
    )
}}