# dbt_claude v0.1.0

## Initial Release
This is the initial release of the Claude dbt package.

## Feature Updates
- Adds the `claude__enterprise_user_activity_pass_through_metrics` variable to allow users to pass through additional numeric metric columns from the `enterprise_user_activity` source table. These are summed into `claude__user_summary` alongside the default activity metrics. For more details, refer to the [Passing Through Additional Fields](README.md#passing-through-additional-fields) section of the README.
- Adds `lifetime_cowork_sessions`, `lifetime_design_messages`, `lifetime_design_sessions`, `lifetime_office_messages`, and `lifetime_office_sessions` (and their `month_to_date_` counterparts) to `claude__user_summary`, extending activity coverage to the Cowork, Design, and Office (Word/Excel/PowerPoint/Outlook) surfaces.
- Adds `is_api_key_deleted` to `claude__platform_cost_usage_report`, sourced from `stg_claude__api_key.is_deleted` via `int_claude__api_key`.
- Adds `is_creator_deleted` to `int_claude__api_key` and `claude__platform_cost_usage_report`, sourced from `stg_claude__users.is_deleted` via the API key's `created_by_id`.