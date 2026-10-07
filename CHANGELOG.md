# dbt_claude v0.1.1

[PR #5](https://github.com/fivetran/dbt_claude/pull/5) includes the following updates: 

## Under the Hood

- Renames all [source identifier](https://github.com/fivetran/dbt_claude#change-the-source-table-references) variables from `claude__<table>_identifier` to `claude_<table>_identifier` (single underscore prefix instead of double). If you have set any of these variables in your `dbt_project.yml`, update them to the new names.
- Ensures the package is backwards-compatible with the `union_data` macro.

# dbt_claude v0.1.0

This is the initial release of the Claude dbt package!

## What does this dbt package do?
This package enables you to understand Claude API cost and usage, Claude Code developer activity, and enterprise user cost and engagement at your company. It allocates organization-level cost down to the API key that consumed it, joins per-user enterprise cost to per-user token usage, and rolls up cost, usage, and product activity into a single summary per enterprise user.

The following table provides a detailed list of all models materialized within this package by default.

| Table | Description |
| :---- | :---- |
| [claude__platform_cost_usage_report](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__platform_cost_usage_report) | Organization cost allocated down to the API key that consumed it, joined with API message usage. One row per API key, day, model, cost type and token type. <br></br>**Example Analytics Questions:**<ul><li>Which API keys or workspaces are driving the most Claude API spend?</li><li>How is cost split between input, output, and cache tokens by model?</li><li>What share of cost can't be attributed to a specific API key, and why?</li></ul>|
| [claude__enterprise_cost_usage_report](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__enterprise_cost_usage_report) | Enterprise per-user cost joined to per-user token usage. One row per actor, day, product, model, cost type and token type. <br></br>**Example Analytics Questions:**<ul><li>Which actors or products are consuming the most enterprise cost and tokens?</li><li>How does per-user Claude spend trend over time by model?</li><li>Which users have usage but no matching cost, or vice versa?</li></ul>|
| [claude__code_report](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__code_report) | Claude Code activity, one row per actor, day, terminal type and customer type. <br></br>**Example Analytics Questions:**<ul><li>Which developers or API keys are most active with Claude Code, by sessions, commits, and pull requests?</li><li>How many lines of code are being added and removed through Claude Code, and by whom?</li><li>What is the estimated Claude Code cost per session?</li></ul>|
| [claude__user_summary](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__user_summary) | One row per enterprise actor, summarizing cost, usage and product activity over two windows: all time and the current calendar month. <br></br>**Example Analytics Questions:**<ul><li>Which users are the heaviest Claude spenders or most active this month versus all time?</li><li>How many workspaces does each user belong to, and what roles do they hold?</li><li>Which enterprise actors have no matching workspace user record (offboarded people or API-only actors)?</li></ul>|