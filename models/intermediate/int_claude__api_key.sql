{{ config(enabled=var('claude_using_api_key', True)) }}

with api_key as (

    select *
    from {{ ref('stg_claude__api_key') }}
),

{% if var('claude_using_users', True) %}
users as (

    select *
    from {{ ref('stg_claude__users') }}
),
{% endif %}

{% if var('claude_using_workspace', True) %}
workspace as (

    select *
    from {{ ref('stg_claude__workspace') }}
),
{% endif %}

final as (

    select
        api_key.*
        {% if var('claude_using_users', True) -%}
        , users.name as created_by_name
        , users.email as created_by_email
        , users.is_deleted as is_creator_deleted
        {% endif %}
        {% if var('claude_using_workspace', True) -%}
        , workspace.name as workspace_name
        {% endif %}
    from api_key
    {% if var('claude_using_users', True) %}
    left join users
        on api_key.created_by_id = users.user_id
        and api_key.source_relation = users.source_relation
        and api_key.created_by_type = 'user'
    {% endif %}
    {% if var('claude_using_workspace', True) -%}
    left join workspace
        on api_key.workspace_id = workspace.workspace_id
        and api_key.source_relation = workspace.source_relation
    {%- endif %}
)

select *
from final
