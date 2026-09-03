{% macro get_organization_columns() %}

{% set columns = [
    {"name": "id",                "datatype": dbt.type_string()},
    {"name": "name",              "datatype": dbt.type_string()},
    {"name": "type",              "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced",  "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
