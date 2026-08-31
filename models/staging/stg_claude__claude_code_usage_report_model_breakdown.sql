
with base as (

    select *
    from {{ ref('stg_claude__claude_code_usage_report_model_breakdown_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__claude_code_usage_report_model_breakdown_tmp')),
                staging_columns=get_claude_code_usage_report_model_breakdown_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        claude_code_usage_report_fivetran_id,
        model,
        tokens_output,
        tokens_input,
        estimated_cost_currency,
        tokens_cache_creation,
        estimated_cost_amount,
        tokens_cache_read,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
