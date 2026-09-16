{% macro get_enterprise_user_usage_report_columns() %}

{% set columns = [
    {"name": "_fivetran_id",                                "datatype": dbt.type_string()},
    {"name": "actor_user_id",                               "datatype": dbt.type_string()},
    {"name": "request",                                     "datatype": dbt.type_int()},
    {"name": "cache_creation_ephemeral_1_h_input_token",    "datatype": dbt.type_int()},
    {"name": "cache_creation_ephemeral_5_m_input_token",    "datatype": dbt.type_int()},
    {"name": "product",                                     "datatype": dbt.type_string()},
    {"name": "starting_date",                               "datatype": dbt.type_timestamp()},
    {"name": "ending_date",                                 "datatype": dbt.type_timestamp()},
    {"name": "output_token",                                "datatype": dbt.type_int()},
    {"name": "data_refreshed_at",                           "datatype": dbt.type_timestamp()},
    {"name": "speed",                                       "datatype": dbt.type_string()},
    {"name": "server_tool_use_web_search_request",          "datatype": dbt.type_int()},
    {"name": "uncached_input_token",                        "datatype": dbt.type_int()},
    {"name": "organization_id",                             "datatype": dbt.type_string()},
    {"name": "model",                                       "datatype": dbt.type_string()},
    {"name": "context_window",                              "datatype": dbt.type_string()},
    {"name": "inference_geo",                               "datatype": dbt.type_string()},
    {"name": "cache_read_input_token",                      "datatype": dbt.type_int()},
    {"name": "total_token",                                 "datatype": dbt.type_int()},
    {"name": "_fivetran_deleted",                           "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced",                            "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
