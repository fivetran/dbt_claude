with api_key as (

    select *
    from {{ ref('stg_claude__api_key') }}
),

users as (

    select *
    from {{ ref('stg_claude__users') }}
),

{% if var('claude__using_workspace', True) %}
workspace as (

    select *
    from {{ ref('stg_claude__workspace') }}
),
{% endif %}

final as (

    select
        api_key.*,
        users.name as created_by_name,
        users.email as created_by_email
        {% if var('claude__using_workspace', True) -%}
        , workspace.name as workspace_name
        {% endif %}
    from api_key
    left join users
        on api_key.created_by_id = users.user_id
        and api_key.source_relation = users.source_relation
        and api_key.created_by_type = 'user'
    {% if var('claude__using_workspace', True) -%}
    left join workspace
        on api_key.workspace_id = workspace.workspace_id
        and api_key.source_relation = workspace.source_relation
    {%- endif %}
)

select *
from final