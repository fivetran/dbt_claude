<!--section="claude_transformation_model"-->
# Claude dbt Package

This dbt package transforms data from Fivetran's Claude connector into analytics-ready tables covering API cost reporting, message usage, Claude Code activity, and enterprise user management.

## Resources

- Number of materialized models¹: 30
- Connector documentation
  - [Claude connector documentation](https://fivetran.com/docs/connectors/applications/claude)
  - [Claude ERD](https://fivetran.com/docs/connectors/applications/claude#schemainformation)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_claude)
  - [dbt Docs](https://fivetran.github.io/dbt_claude/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_claude/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_claude/blob/main/CHANGELOG.md)
- dbt Core™ supported versions
  - `>=1.3.0, <3.0.0`

## What does this dbt package do?
This package enables you to understand Claude API cost and usage, Claude Code developer activity, and enterprise user cost and engagement at your company. It allocates organization-level cost down to the API key that consumed it, joins per-user enterprise cost to per-user token usage, and rolls up cost, usage, and product activity into a single summary per enterprise user.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<target_schema>_claude_reports
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [claude__platform_cost_usage_report](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__platform_cost_usage_report) | Organization cost allocated down to the API key that consumed it, joined with API message usage. One row per API key, day, model, cost type and token type. <br></br>**Example Analytics Questions:**<ul><li>Which API keys or workspaces are driving the most Claude API spend?</li><li>How is cost split between input, output, and cache tokens by model?</li><li>What share of cost can't be attributed to a specific API key, and why?</li></ul>|
| [claude__enterprise_cost_usage_report](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__enterprise_cost_usage_report) | Enterprise per-user cost joined to per-user token usage. One row per actor, day, product, model, cost type and token type. <br></br>**Example Analytics Questions:**<ul><li>Which actors or products are consuming the most enterprise cost and tokens?</li><li>How does per-user Claude spend trend over time by model?</li><li>Which users have usage but no matching cost, or vice versa?</li></ul>|
| [claude__code_report](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__code_report) | Claude Code activity, one row per actor, day, terminal type and customer type. <br></br>**Example Analytics Questions:**<ul><li>Which developers or API keys are most active with Claude Code, by sessions, commits, and pull requests?</li><li>How many lines of code are being added and removed through Claude Code, and by whom?</li><li>What is the estimated Claude Code cost per session?</li></ul>|
| [claude__user_summary](https://fivetran.github.io/dbt_claude/#!/model/model.claude.claude__user_summary) | One row per enterprise actor, summarizing cost, usage and product activity over two windows: all time and the current calendar month. <br></br>**Example Analytics Questions:**<ul><li>Which users are the heaviest Claude spenders or most active this month versus all time?</li><li>How many workspaces does each user belong to, and what roles do they hold?</li><li>Which enterprise actors have no matching workspace user record (offboarded people or API-only actors)?</li></ul>|

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Claude connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **Databricks**, or **DuckDB** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_claude/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the package
Include the following claude package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/claude
    version: [">=0.1.0", "<0.2.0"]
```

### Define database and schema variables
#### Option A: Single connection
By default, this package runs using your destination and the `anthropic_claude` schema. If this is not where your Claude data is (for example, if your Claude schema is named `claude_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    claude_database: your_destination_name
    claude_schema: your_schema_name
```

#### Option B: Union multiple connections
If you have multiple Claude connections in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. For each source table, the package will union all of the data together and pass the unioned table into the transformations. The `source_relation` column in each model indicates the origin of each record.

To use this functionality, you will need to set the `claude_sources` variable in your root `dbt_project.yml` file:

```yml
# dbt_project.yml

vars:
  claude:
    claude_sources:
      - database: connection_1_destination_name # Required
        schema: connection_1_schema_name # Required
        name: connection_1_source_name # Required only if following the step in the following subsection

      - database: connection_2_destination_name
        schema: connection_2_schema_name
        name: connection_2_source_name
```

#### Optional: Incorporate unioned sources into DAG

If you use [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore) and are unioning multiple Claude connections, you can define your sources in a property `.yml` file, [using this as a template](https://github.com/fivetran/dbt_claude/blob/main/models/staging/src_claude.yml). Set the variable `has_defined_sources: true` under the Claude namespace in your `dbt_project.yml`. Otherwise, your Claude connections won't appear in your DAG. See the `union_connections` macro [documentation](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#optional-union-connections-defined-sources-configuration) for full configuration details.

### Disable models for non-existent sources
Your Claude connection might not sync every table that this package expects. If your syncs exclude certain tables, it is because you either do not use that functionality in Claude or have actively excluded some tables from your syncs.

To disable the corresponding functionality in the package, you must set the relevant config variables to `false`. By default, all variables are set to `true`. Alter variables only for the tables you want to disable:

```yml
vars:
    claude_using_cost_report: false # Disable if you do not have COST_REPORT synced.
    claude_using_enterprise_user_cost_report: false # Disable if you do not have ENTERPRISE_USER_COST_REPORT synced.
    claude_using_message_usage_report: false # Disable if you do not have MESSAGE_USAGE_REPORT synced.
    claude_using_enterprise_user_usage_report: false # Disable if you do not have ENTERPRISE_USER_USAGE_REPORT synced.
    claude_using_claude_code_usage_report: false # Disable if you do not have CLAUDE_CODE_USAGE_REPORT synced.
    claude_using_claude_code_usage_report_model_breakdown: false # Disable if you do not have CLAUDE_CODE_USAGE_REPORT_MODEL_BREAKDOWN synced.
    claude_using_users: false # Disable if you do not have USERS synced.
    claude_using_enterprise_user_actor: false # Disable if you do not have ENTERPRISE_USER_ACTOR synced.
    claude_using_api_key: false # Disable if you do not have API_KEY synced.
    claude_using_enterprise_user_activity: false # Disable if you do not have ENTERPRISE_USER_ACTIVITY synced.
    claude_using_organization: false # Disable if you do not have ORGANIZATION synced. Removes the organization_name column and the join to it from the claude__code_report and claude__enterprise_cost_usage_report transform models.
    claude_using_workspace: false # Disable if you do not have WORKSPACE synced. Removes the workspace_name column and the join to it from int_claude__api_key, claude__platform_cost_usage_report, and claude__user_summary.
    claude_using_workspace_member: false # Disable if you do not have WORKSPACE_MEMBER synced. Removes the count_workspaces, workspace_names, is_workspace_admin, and is_workspace_developer columns from claude__user_summary.
```

### (Optional) Additional configurations
<details open><summary>Expand/Collapse details</summary>

#### Passing Through Additional Fields
This package includes all source columns defined in the macros folder. You can add more columns using our pass-through column variables. These variables allow for the pass-through fields to be aliased (`alias`) and casted (`transform_sql`) if desired, but not required. Datatype casting is configured via a sql snippet within the `transform_sql` key. You may add the desired sql while omitting the `as field_name` at the end and your custom pass-through fields will be casted accordingly. Use the below format for declaring the respective pass-through variables:

```yml
# dbt_project.yml

vars:
  claude__enterprise_user_activity_pass_through_metrics:
    - name: "that_field"
      alias: "renamed_to_this_field"
      transform_sql: "cast(renamed_to_this_field as string)"
    - name: "this_field"
```

`claude__enterprise_user_activity_pass_through_metrics` fields are expected to be numeric metrics; they are summed into the `lifetime_<field>`/`month_to_date_<field>` columns of `claude__user_summary` alongside the default activity metrics.

> Please create an [issue](https://github.com/fivetran/dbt_claude/issues) if you'd like to see passthrough column support for other tables in the Claude schema.

#### Enabling Cent to Dollar Conversion
Cost-based fields, such as `amount` and `estimated_cost_amount`, are reported by the Claude API in the smallest denomination of the currency (cents, or fractional cents on some endpoints, for USD). By default, this package divides these fields by 100 in staging so every downstream cost column is in major currency units (dollars for USD) instead.

If you'd rather keep these fields in their raw, undivided form, set `claude__convert_cost` to `false` in your `dbt_project.yml`:

```yml
vars:
    claude__convert_cost: false # default is true
```

Claude cost is currently always reported in USD, so this conversion is safe and enabled by default. If Claude later reports cost in a currency with no minor unit, this variable lets you turn the conversion off without editing the package.

#### Changing the Build Schema
By default this package will build the Claude staging and intermediate models within a schema titled (<target_schema> + `_stg_claude`) and the final transform models within a schema titled (<target_schema> + `_claude_reports`) in your target database. If this is not where you would like your Claude staging, intermediate, and final models to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
models:
    claude:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      intermediate: # ephemeral by default
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```

#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`src_claude.yml`](https://github.com/fivetran/dbt_claude/blob/main/models/staging/src_claude.yml) source declarations to see the expected names.

```yml
vars:
    claude_<default_source_table_name>_identifier: your_table_name
```

#### Source casing for case-sensitive destinations
By default, the package applies case-insensitive comparisons when resolving `source_relation` values. If your destination is case-sensitive and you want downstream transformations to respect the exact casing of your source database and schema names, set the following variable:

```yml
vars:
    fivetran_using_source_casing: true
```
</details>

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt/setup-guide#transformationsfordbtcoresetupguide).
</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.

```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```

<!--section="claude_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/claude/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_claude/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_claude/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
