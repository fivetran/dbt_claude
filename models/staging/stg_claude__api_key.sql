
with base as (

    select *
    from {{ ref('stg_claude__api_key_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__api_key_tmp')),
                staging_columns=get_api_key_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        id as api_key_id,
        workspace_id,
        name,
        partial_key_hint,
        status,
        created_at,
        created_by_id,
        created_by_type,
        _fivetran_synced

    from fields

    {# where not coalesce(_fivetran_deleted, false) #}
)

select * from final
