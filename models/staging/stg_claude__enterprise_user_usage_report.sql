
with base as (

    select *
    from {{ ref('stg_claude__enterprise_user_usage_report_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__enterprise_user_usage_report_tmp')),
                staging_columns=get_enterprise_user_usage_report_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        _fivetran_id as enterprise_user_usage_report_id,
        actor_user_id,
        request,
        cache_creation_ephemeral_1_h_input_token,
        cache_creation_ephemeral_5_m_input_token,
        product,
        cast(starting_date as date) as starting_date,
        cast(ending_date as date) as ending_date,
        output_token,
        data_refreshed_at,
        speed,
        server_tool_use_web_search_request,
        uncached_input_token,
        organization_id,
        model,
        context_window,
        inference_geo,
        cache_read_input_token,
        total_token,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
