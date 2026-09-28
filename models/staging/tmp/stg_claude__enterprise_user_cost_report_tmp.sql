{{ config(enabled=var('claude__using_enterprise_user_cost_report', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='claude_sources',
        single_source_name='claude',
        single_table_name='enterprise_user_cost_report'
    )
}}