{% macro get_workspace_member_columns() %}

{% set columns = [
    {"name": "user_id",           "datatype": dbt.type_string()},
    {"name": "workspace_id",      "datatype": dbt.type_string()},
    {"name": "type",              "datatype": dbt.type_string()},
    {"name": "workspace_role",    "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced",  "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
