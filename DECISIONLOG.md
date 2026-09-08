# Decision Log

In creating this package, which is meant for a wide range of use cases, we had to take opinionated stances on a few different questions we came across during development. We've consolidated significant choices we made here, and will continue to update as the package evolves.

## Non-Token Cost Is Allocated, Not Parked

Web search and session-usage cost don't carry a model or token type, so unlike token cost they can't be spread by token share. Rather than leaving this cost entirely unallocated at the workspace level, `claude__platform_cost_usage_report` allocates what it can: web search cost by each API key's actual share of web search requests that day (exact, since web search bills at a flat rate per request), and any cost still unmatched is carried as its own `unallocated` row rather than being dropped, so `claude_cost` always ties back to the total in `stg_claude__cost_report`.

## Session-Usage and Code-Execution Cost Stays Unallocated

`claude__platform_cost_usage_report`'s token-share allocation joins on `model` in addition to date, workspace, and token type. Session-usage and code-execution cost report no model at all, so they never match that join and fall through to the `unallocated` branch. We considered widening the join to an overall, model-agnostic token share so this cost would land on individual API keys, but decided against it — mixing an exact per-model allocation with an approximate model-agnostic one in the same column would make `claude_cost` harder to reason about, and the unallocated remainder already reconciles to source and is clearly labeled via `allocation_method`.

## `claude__code_report` Resolves Identity Through `stg_claude__users`, Not `stg_claude__enterprise_user_actor`

`claude__enterprise_cost_usage_report` and `claude__user_summary` resolve actor identity through `stg_claude__enterprise_user_actor`, the identity table built specifically for enterprise cost and usage reporting. `claude__code_report` instead resolves through `stg_claude__users`, the workspace-membership table, because doing so surfaces the actor's organization role (`user_role`) directly — something `stg_claude__enterprise_user_actor` doesn't carry. The tradeoff: only actors who also appear as workspace users resolve to a name and role this way. A pure API-key actor, or a person who left the organization before ever appearing in `WORKSPACE_MEMBER`, will show a NULL `user_id`/`user_name`/`user_role` here even though they may resolve fine in the other two reports.

## Some Soft-Deleted Records Are Kept, Not Filtered

`stg_claude__users`, `stg_claude__enterprise_user_actor`, and `stg_claude__workspace` all keep soft-deleted and offboarded records rather than filtering them out, exposing an `is_deleted` column instead. This is deliberate: cost and usage data is historical, so an actor who has since left the organization should still resolve to a name in `claude__user_summary` and `claude__code_report` — filtering deleted records out of staging would leave that historical activity attached to a NULL identity instead.
