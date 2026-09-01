
with base as (

    select *
    from {{ ref('stg_claude__enterprise_user_actor_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__enterprise_user_actor_tmp')),
                staging_columns=get_enterprise_user_actor_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        id as actor_id,
        deleted as is_deleted,
        name,
        {# type, -- always user_actor #}
        lower(email) as email,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, deleted, false)
)

select * from final
