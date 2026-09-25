{{ config(enabled=var('claude_using_cost_report', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='claude_sources',
        single_source_name='claude',
        single_table_name='cost_report'
    )
}}