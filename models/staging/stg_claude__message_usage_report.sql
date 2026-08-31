
with base as (

    select *
    from {{ ref('stg_claude__message_usage_report_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__message_usage_report_tmp')),
                staging_columns=get_message_usage_report_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        _fivetran_id as message_usage_report_id,
        api_key_id,
        workspace_id,
        cache_creation_ephemeral_1_h_input_token,
        cache_creation_ephemeral_5_m_input_token,
        cast(starting_at as date) as starting_at,
        cast(ending_at as date) as ending_at,
        output_token,
        server_tool_use_web_search_request,
        uncached_input_token,
        model,
        service_tier,
        context_window,
        cache_read_input_token,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
