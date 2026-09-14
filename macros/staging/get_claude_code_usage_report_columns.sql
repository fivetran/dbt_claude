{% macro get_claude_code_usage_report_columns() %}

{% set columns = [
    {"name": "_fivetran_id",                                    "datatype": dbt.type_string()},
    {"name": "organization_id",                                 "datatype": dbt.type_string()},
    {"name": "customer_type",                                   "datatype": dbt.type_string()},
    {"name": "date",                                            "datatype": dbt.type_timestamp()},
    {"name": "terminal_type",                                   "datatype": dbt.type_string()},
    {"name": "actor_type",                                      "datatype": dbt.type_string()},
    {"name": "actor_api_key_name",                              "datatype": dbt.type_string()},
    {"name": "actor_email_address",                             "datatype": dbt.type_string()},
    {"name": "core_metrics_pull_requests_by_claude_code",       "datatype": dbt.type_int()},
    {"name": "core_metrics_lines_of_code_removed",              "datatype": dbt.type_int()},
    {"name": "core_metrics_lines_of_code_added",                "datatype": dbt.type_int()},
    {"name": "core_metrics_commits_by_claude_code",             "datatype": dbt.type_int()},
    {"name": "core_metrics_num_sessions",                       "datatype": dbt.type_int()},
    {"name": "_fivetran_deleted",                               "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced",                                "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
