{{ config(enabled=var('claude_using_workspace', True)) }}

with base as (

    select *
    from {{ ref('stg_claude__workspace_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__workspace_tmp')),
                staging_columns=get_workspace_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        id as workspace_id,
        name,
        created_at,
        display_color,
        data_residency_workspace_geo,
        data_residency_default_inference_geo,
        data_residency_allowed_inference_geo,
        _fivetran_synced,
        _fivetran_deleted as is_deleted

    from fields
)

select * from final
