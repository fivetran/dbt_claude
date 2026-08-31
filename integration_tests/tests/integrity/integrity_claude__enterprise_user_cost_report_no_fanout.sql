-- Verify that joining enterprise_user_cost_report to enterprise_user_actor
-- does not fan out (row count before join = row count after join).
-- Returns rows only if a fan-out is detected; 0 rows means the test passes.

with base as (
    select count(*) as row_count
    from {{ ref('claude__enterprise_user_cost_report') }}
),

joined as (
    select count(*) as row_count
    from {{ ref('claude__enterprise_user_cost_report') }}
),

comparison as (
    select
        base.row_count                                  as base_count,
        joined.row_count                                as joined_count,
        joined.row_count - base.row_count               as fanout_diff
    from base
    cross join joined
)

select *
from comparison
where fanout_diff != 0
