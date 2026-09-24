{{ config(enabled=var('claude__using_enterprise_user_cost_report', True)) }}

with base as (

    select *
    from {{ ref('stg_claude__enterprise_user_cost_report_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__enterprise_user_cost_report_tmp')),
                staging_columns=get_enterprise_user_cost_report_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        _fivetran_id as enterprise_user_cost_report_id,
        actor_user_id,
        cast(starting_date as date) as starting_date,
        cast(ending_date as date) as ending_date,
        product,
        coalesce(cast(amount as {{ dbt.type_float() }}), 0) / 100 as amount, -- converted from fractional cents to major currency units
        coalesce(cast(list_amount as {{ dbt.type_float() }}), 0) / 100 as list_amount, -- converted from fractional cents to major currency units
        currency,
        lower(cost_type) as cost_type,
        lower(token_type) as token_type,
        case lower(token_type)
            when 'uncached_input_tokens' then 'input'
            when 'cache_read_input_tokens' then 'cache_read'
            when 'cache_creation.ephemeral_5m_input_tokens' then 'cache_creation_5m'
            when 'cache_creation.ephemeral_1h_input_tokens' then 'cache_creation_1h'
            when 'output_tokens' then 'output'
            else nullif(lower(token_type), '')
        end as token_unit_type,
        data_refreshed_at,
        speed,
        organization_id,
        lower(model) as model,
        context_window,
        inference_geo,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
