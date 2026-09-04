{{ config(enabled=var('claude__using_workspace', True)) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='claude_sources',
        single_source_name='claude',
        single_table_name='workspace'
    )
}}