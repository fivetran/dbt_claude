{% macro get_workspace_columns() %}

{% set columns = [
    {"name": "id",                                   "datatype": dbt.type_string()},
    {"name": "name",                                 "datatype": dbt.type_string()},
    {"name": "created_at",                           "datatype": dbt.type_timestamp()},
    {"name": "display_color",                        "datatype": dbt.type_string()},
    {"name": "type",                                 "datatype": dbt.type_string()},
    {"name": "data_residency_workspace_geo",         "datatype": dbt.type_string()},
    {"name": "data_residency_default_inference_geo", "datatype": dbt.type_string()},
    {"name": "data_residency_allowed_inference_geo", "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted",                    "datatype": "boolean"},
    {"name": "_fivetran_synced",                     "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
