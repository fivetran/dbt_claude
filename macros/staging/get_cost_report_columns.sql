{% macro get_cost_report_columns() %}

{% set columns = [
    {"name": "_fivetran_id",      "datatype": dbt.type_string()},
    {"name": "workspace_id",      "datatype": dbt.type_string()},
    {"name": "amount",            "datatype": dbt.type_float()},
    {"name": "cost_type",         "datatype": dbt.type_string()},
    {"name": "starting_at",       "datatype": dbt.type_timestamp()},
    {"name": "ending_at",         "datatype": dbt.type_timestamp()},
    {"name": "description",       "datatype": dbt.type_string()},
    {"name": "token_type",        "datatype": dbt.type_string()},
    {"name": "model",             "datatype": dbt.type_string()},
    {"name": "service_tier",      "datatype": dbt.type_string()},
    {"name": "currency",          "datatype": dbt.type_string()},
    {"name": "context_window",    "datatype": dbt.type_string()},
    {"name": "inference_geo",     "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced",  "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
