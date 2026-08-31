{% macro get_enterprise_user_cost_report_columns() %}
{% set columns = [
    {"name": "_fivetran_id",        "datatype": dbt.type_string()},
    {"name": "actor_user_id",       "datatype": dbt.type_string()},
    {"name": "product",             "datatype": dbt.type_string()},
    {"name": "amount",              "datatype": dbt.type_float()},
    {"name": "list_amount",         "datatype": dbt.type_float()},
    {"name": "starting_date",       "datatype": dbt.type_timestamp()},
    {"name": "ending_date",         "datatype": dbt.type_timestamp()},
    {"name": "cost_type",           "datatype": dbt.type_string()},
    {"name": "token_type",          "datatype": dbt.type_string()},
    {"name": "data_refreshed_at",   "datatype": dbt.type_timestamp()},
    {"name": "speed",               "datatype": dbt.type_string()},
    {"name": "organization_id",     "datatype": dbt.type_string()},
    {"name": "model",               "datatype": dbt.type_string()},
    {"name": "currency",            "datatype": dbt.type_string()},
    {"name": "context_window",      "datatype": dbt.type_string()},
    {"name": "inference_geo",       "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted",   "datatype": "boolean"},
    {"name": "_fivetran_synced",    "datatype": dbt.type_timestamp()}
] %}
{{ return(columns) }}
{% endmacro %}
