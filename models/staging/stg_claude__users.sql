{{ config(enabled=var('claude_using_users', True)) }}

with base as (

    select *
    from {{ ref('stg_claude__users_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__users_tmp')),
                staging_columns=get_users_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        id as user_id,
        added_at,
        role,
        name,
        lower(email) as email,
        _fivetran_synced,
        _fivetran_deleted as is_deleted

    from fields
)

select * from final
