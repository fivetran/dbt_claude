{{ config(enabled=var('claude__using_enterprise_user_activity', True)) }}

{% if var('claude_union_schemas', []) | length > 0 or var('claude_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='enterprise_user_activity',
        database_variable='claude_database',
        schema_variable='claude_schema',
        default_database=target.database,
        default_schema='anthropic_claude',
        default_variable='enterprise_user_activity',
        union_schema_variable='claude_union_schemas',
        union_database_variable='claude_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='claude_sources',
        single_source_name='claude',
        single_table_name='enterprise_user_activity'
    )
}}

{% endif %}