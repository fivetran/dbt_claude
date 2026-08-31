
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
        product,
        amount,
        list_amount,
        cast(starting_date as date) as starting_date,
        cast(ending_date as date) as ending_date,
        cost_type,
        token_type,
        data_refreshed_at,
        speed,
        organization_id,
        model,
        currency,
        context_window,
        inference_geo,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
