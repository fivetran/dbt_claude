{% macro get_users_columns() %}

{% set columns = [
    {"name": "id",                "datatype": dbt.type_string()},
    {"name": "added_at",          "datatype": dbt.type_timestamp()},
    {"name": "role",              "datatype": dbt.type_string()},
    {"name": "name",              "datatype": dbt.type_string()},
    {"name": "type",              "datatype": dbt.type_string()},
    {"name": "email",             "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced",  "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
