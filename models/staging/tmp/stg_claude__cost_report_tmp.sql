{{ config(enabled=var('claude__using_cost_report', True)) }}

{% if var('claude_union_schemas', []) | length > 0 or var('claude_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='cost_report',
        database_variable='claude_database',
        schema_variable='claude_schema',
        default_database=target.database,
        default_schema='anthropic_claude',
        default_variable='cost_report',
        union_schema_variable='claude_union_schemas',
        union_database_variable='claude_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='claude_sources',
        single_source_name='claude',
        single_table_name='cost_report'
    )
}}

{% endif %}