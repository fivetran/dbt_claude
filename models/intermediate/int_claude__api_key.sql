with api_key as (

    select *
    from {{ ref('stg_claude__api_key') }}
),

users as (

    select *
    from {{ ref('stg_claude__users') }}
),

workspace as (

    select *
    from {{ ref('stg_claude__workspace') }}
),

final as (

    select
        api_key.*,
        users.name as created_by_name,
        users.email as created_by_email,
        workspace.name as workspace_name
    from api_key 
    left join users 
        on api_key.created_by_id = users.user_id
        and api_key.source_relation = users.source_relation
        and api_key.created_by_type = 'user'
    left join workspace 
        on api_key.workspace_id = workspace.workspace_id
        and api_key.source_relation = workspace.source_relation
)

select *
from final