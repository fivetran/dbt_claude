{% macro get_enterprise_user_activity_columns() %}

{% set columns = [
    {"name": "date",                                                               "datatype": "date"},
    {"name": "user_id",                                                            "datatype": dbt.type_string()},
    {"name": "chat_metrics_distinct_conversation_count",                           "datatype": dbt.type_int()},
    {"name": "chat_metrics_message_count",                                         "datatype": dbt.type_int()},
    {"name": "claude_code_metrics_core_metrics_commit_count",                      "datatype": dbt.type_int()},
    {"name": "claude_code_metrics_core_metrics_distinct_session_count",            "datatype": dbt.type_int()},
    {"name": "claude_code_metrics_core_metrics_lines_of_code_added_count",         "datatype": dbt.type_int()},
    {"name": "claude_code_metrics_core_metrics_lines_of_code_removed_count",       "datatype": dbt.type_int()},
    {"name": "claude_code_metrics_core_metrics_pull_request_count",                "datatype": dbt.type_int()},
    {"name": "cowork_metrics_distinct_session_count",                              "datatype": dbt.type_int()},
    {"name": "cowork_metrics_message_count",                                       "datatype": dbt.type_int()},
    {"name": "design_metrics_distinct_session_count",                              "datatype": dbt.type_int()},
    {"name": "design_metrics_message_count",                                       "datatype": dbt.type_int()},
    {"name": "office_metrics_excel_distinct_session_count",                        "datatype": dbt.type_int()},
    {"name": "office_metrics_excel_message_count",                                 "datatype": dbt.type_int()},
    {"name": "office_metrics_outlook_distinct_session_count",                      "datatype": dbt.type_int()},
    {"name": "office_metrics_outlook_message_count",                               "datatype": dbt.type_int()},
    {"name": "office_metrics_powerpoint_distinct_session_count",                   "datatype": dbt.type_int()},
    {"name": "office_metrics_powerpoint_message_count",                            "datatype": dbt.type_int()},
    {"name": "office_metrics_word_distinct_session_count",                         "datatype": dbt.type_int()},
    {"name": "office_metrics_word_message_count",                                  "datatype": dbt.type_int()},
    {"name": "web_search_count",                                                   "datatype": dbt.type_int()},
    {"name": "_fivetran_deleted",                                                  "datatype": "boolean"},
    {"name": "_fivetran_synced",                                                   "datatype": dbt.type_timestamp()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('claude__enterprise_user_activity_pass_through_metrics')) }}

{{ return(columns) }}

{% endmacro %}
