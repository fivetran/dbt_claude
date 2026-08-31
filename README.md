# dbt_claude

This dbt package transforms data from the [Fivetran Claude connector](https://fivetran.com/docs/connectors/applications/claude) into analytics-ready models covering API cost reporting, message usage, Claude Code activity, and enterprise user management.

## Requirements

- dbt version >= 1.3.0
- Supported destinations: BigQuery, Snowflake, Redshift, Databricks, Spark
- A Fivetran Claude connector syncing to your warehouse

## Installation

Add the package to your `packages.yml`:

```yaml
packages:
  - package: fivetran/dbt_claude
    version: [">=0.1.0", "<0.2.0"]
```

Then run:

```bash
dbt deps
```

## Configuration

By default, this package looks for your Claude data in the `anthropic_claude` schema of your target database. You can configure this in your `dbt_project.yml`:

```yaml
vars:
  claude_schema: anthropic_claude        # schema where Fivetran syncs Claude data
  claude_database: your_database         # database override (defaults to target.database)
```

If your source table names differ from the Fivetran defaults, override the identifier variables:

| Variable | Default | Description |
|---|---|---|
| `claude__cost_report_identifier` | `cost_report` | Organization-level cost report table |
| `claude__enterprise_user_cost_report_identifier` | `enterprise_user_cost_report` | Per-user cost breakdown table |
| `claude__message_usage_report_identifier` | `message_usage_report` | API message usage table |
| `claude__enterprise_user_usage_report_identifier` | `enterprise_user_usage_report` | Per-user token usage table |
| `claude__claude_code_usage_report_identifier` | `claude_code_usage_report` | Claude Code activity table |
| `claude__claude_code_usage_report_model_breakdown_identifier` | `claude_code_usage_report_model_breakdown` | Claude Code per-model breakdown table |
| `claude__users_identifier` | `users` | Workspace users table |
| `claude__enterprise_user_actor_identifier` | `enterprise_user_actor` | Enterprise actor table |

## Final Models

| Model | Description |
|---|---|
| `claude__cost_report` | Organization-level API costs by model, token type, and time period |
| `claude__message_usage_report` | API message usage by model, workspace, and API key |
| `claude__enterprise_user_cost_report` | Per-user API costs enriched with actor name and email |
| `claude__enterprise_user_usage_report` | Per-user token usage enriched with actor name and email |
| `claude__claude_code_usage_report` | Claude Code sessions, commits, and lines-of-code metrics by actor and date |
| `claude__claude_code_usage_report_model_breakdown` | Claude Code token and cost breakdown by session and model |
| `claude__users` | Workspace users with role and membership metadata |
| `claude__enterprise_user_actor` | Enterprise actors referenced in usage and cost reports |

## Running the Package

```bash
dbt deps
dbt run --select dbt_claude
dbt test --select dbt_claude
```
