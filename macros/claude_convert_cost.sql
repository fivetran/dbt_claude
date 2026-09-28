{% macro claude_convert_cost(field_name, divide_by=100.0, divide_var=var('claude__convert_cost', true), alias=none) %}
    {{ return(adapter.dispatch('claude_convert_cost', 'claude')(field_name, divide_by, divide_var, alias)) }}
{% endmacro %}

{% macro default__claude_convert_cost(field_name, divide_by=100.0, divide_var=var('claude__convert_cost', true), alias=none) %}

    {% if divide_var %}
        {{ field_name }} / {{ divide_by }} as {{ alias if alias else field_name }}
    {% else %}
        {{ field_name }} as {{ alias if alias else field_name }}
    {% endif %}

{% endmacro %}
