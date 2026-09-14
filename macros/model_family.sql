{% macro model_family(field) %}
    {{ return(adapter.dispatch('model_family', 'claude')(field)) }}
{% endmacro %}

{% macro default__model_family(field) %}

    case
        when lower({{ field }}) like '%opus%' then 'opus'
        when lower({{ field }}) like '%sonnet%' then 'sonnet'
        when lower({{ field }}) like '%fable%' then 'fable'
        when lower({{ field }}) like '%haiku%' then 'haiku'
        else null
    end

{% endmacro %}
