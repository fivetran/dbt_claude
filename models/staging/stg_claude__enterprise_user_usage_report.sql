{{ config(enabled=var('claude__using_enterprise_user_usage_report', True)) }}

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
        cast(starting_date as date) as starting_date,
        cast(ending_date as date) as ending_date,
        lower(product) as product,
        speed,
        organization_id,
        lower(model) as model,
        context_window,
        inference_geo,
        data_refreshed_at,
        coalesce(cache_creation_ephemeral_1_h_input_token, 0) as cache_creation_ephemeral_1_h_input_token,
        coalesce(cache_creation_ephemeral_5_m_input_token, 0) as cache_creation_ephemeral_5_m_input_token,
        coalesce(cache_read_input_token, 0) as cache_read_input_token,
        coalesce(uncached_input_token, 0) as uncached_input_token,
        coalesce(output_token, 0) as output_token,
        coalesce(total_token, 0) as total_token,
        coalesce(request, 0) as request,
        coalesce(server_tool_use_web_search_request, 0) as server_tool_use_web_search_request,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
