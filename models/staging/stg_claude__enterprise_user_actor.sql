{{ config(enabled=var('claude_using_enterprise_user_actor', True)) }}

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
        id as actor_user_id,
        coalesce(deleted, _fivetran_deleted) as is_deleted,
        name,
        lower(email) as email,
        _fivetran_synced

    from fields
)

select * from final
