{{ config(enabled=var('claude__using_cost_report', True)) }}

with base as (

    select *
    from {{ ref('stg_claude__cost_report_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__cost_report_tmp')),
                staging_columns=get_cost_report_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        _fivetran_id as cost_report_id,
        workspace_id,
        cast(starting_at as {{ dbt.type_timestamp() }}) as starting_at,
        cast(ending_at as {{ dbt.type_timestamp() }}) as ending_at,
        cast(starting_at as date) as starting_date,
        cast(ending_at as date) as ending_date,
        coalesce(cast(amount as {{ dbt.type_float() }}), 0) / 100 as amount, -- converted from cents to major currency units
        currency, -- always USD as of Sep 2026
        lower(cost_type) as cost_type,
        description,
        lower(token_type) as token_type,
        case lower(token_type)
            when 'uncached_input_tokens' then 'input'
            when 'cache_read_input_tokens' then 'cache_read'
            when 'cache_creation.ephemeral_5m_input_tokens' then 'cache_creation_5m'
            when 'cache_creation.ephemeral_1h_input_tokens' then 'cache_creation_1h'
            when 'output_tokens' then 'output'
            else nullif(lower(token_type), '')
        end as token_unit_type,
        model,
        service_tier,
        context_window,
        inference_geo,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
