{% macro get_claude_code_usage_report_model_breakdown_columns() %}

{% set columns = [
    {"name": "claude_code_usage_report_fivetran_id",    "datatype": dbt.type_string()},
    {"name": "model",                                   "datatype": dbt.type_string()},
    {"name": "tokens_output",                           "datatype": dbt.type_int()},
    {"name": "tokens_input",                            "datatype": dbt.type_int()},
    {"name": "estimated_cost_currency",                 "datatype": dbt.type_string()},
    {"name": "tokens_cache_creation",                   "datatype": dbt.type_int()},
    {"name": "estimated_cost_amount",                   "datatype": dbt.type_int()},
    {"name": "tokens_cache_read",                       "datatype": dbt.type_int()},
    {"name": "_fivetran_deleted",                       "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced",                        "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
