{% macro get_message_usage_report_columns() %}
{% set columns = [
    {"name": "_fivetran_id",                                "datatype": dbt.type_string()},
    {"name": "api_key_id",                                  "datatype": dbt.type_string()},
    {"name": "workspace_id",                                "datatype": dbt.type_string()},
    {"name": "cache_creation_ephemeral_1_h_input_token",    "datatype": dbt.type_int()},
    {"name": "cache_creation_ephemeral_5_m_input_token",    "datatype": dbt.type_int()},
    {"name": "starting_at",                                 "datatype": dbt.type_timestamp()},
    {"name": "ending_at",                                   "datatype": dbt.type_timestamp()},
    {"name": "output_token",                                "datatype": dbt.type_int()},
    {"name": "server_tool_use_web_search_request",          "datatype": dbt.type_int()},
    {"name": "uncached_input_token",                        "datatype": dbt.type_int()},
    {"name": "model",                                       "datatype": dbt.type_string()},
    {"name": "service_tier",                                "datatype": dbt.type_string()},
    {"name": "context_window",                              "datatype": dbt.type_string()},
    {"name": "cache_read_input_token",                      "datatype": dbt.type_int()},
    {"name": "_fivetran_deleted",                           "datatype": "boolean"},
    {"name": "_fivetran_synced",                            "datatype": dbt.type_timestamp()}
] %}
{{ return(columns) }}
{% endmacro %}
