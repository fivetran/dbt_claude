-- Consistency test: compare row count in the dev schema vs. the prod schema.
-- Returns rows only when the counts differ; 0 rows means the test passes.
-- Set prod_schema var to your production schema to enable this test.

{% set prod_schema = var('prod_schema', target.schema) %}

with dev as (
    select count(*) as row_count
    from {{ target.database }}.{{ target.schema }}.claude__cost_report
),

prod as (
    select count(*) as row_count
    from {{ target.database }}.{{ prod_schema }}.claude__cost_report
),

comparison as (
    select
        dev.row_count   as dev_count,
        prod.row_count  as prod_count
    from dev
    cross join prod
)

select *
from comparison
where dev_count != prod_count
