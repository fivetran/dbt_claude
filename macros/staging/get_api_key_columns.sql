{% macro get_api_key_columns() %}

{% set columns = [
    {"name": "id",                "datatype": dbt.type_string()},
    {"name": "workspace_id",      "datatype": dbt.type_string()},
    {"name": "name",              "datatype": dbt.type_string()},
    {"name": "partial_key_hint",  "datatype": dbt.type_string()},
    {"name": "type",              "datatype": dbt.type_string()},
    {"name": "status",            "datatype": dbt.type_string()},
    {"name": "created_at",        "datatype": dbt.type_timestamp()},
    {"name": "created_by_id",     "datatype": dbt.type_string()},
    {"name": "created_by_type",   "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced",  "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
