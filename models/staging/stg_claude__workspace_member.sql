{{ config(enabled=var('claude_using_workspace_member', True)) }}

with base as (

    select *
    from {{ ref('stg_claude__workspace_member_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_claude__workspace_member_tmp')),
                staging_columns=get_workspace_member_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='claude') }}

    from base
),

final as (

    select
        source_relation,
        user_id,
        workspace_id,
        lower(workspace_role) as workspace_role,
        _fivetran_synced

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final
