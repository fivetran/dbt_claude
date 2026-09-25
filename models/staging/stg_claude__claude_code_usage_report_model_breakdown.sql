{{ config(enabled=var('claude_using_claude_code_usage_report_model_breakdown', True)) }}

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
        lower(model) as model,
        coalesce(tokens_output, 0) as tokens_output,
        coalesce(tokens_input, 0) as tokens_input,
        coalesce(tokens_cache_creation, 0) as tokens_cache_creation,
        coalesce(tokens_cache_read, 0) as tokens_cache_read,
        estimated_cost_currency,
        coalesce(cast(estimated_cost_amount as {{ dbt.type_float() }}), 0) / 100 as estimated_cost_amount, -- converted from cents to major currency units
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
