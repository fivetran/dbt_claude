{% macro model_variant(field) %}
    {{ return(adapter.dispatch('model_variant', 'claude')(field)) }}
{% endmacro %}

{% macro default__model_variant(field) %}

{%- set base = "lower(replace(replace(" ~ field ~ ", '[1m]', ''), '.', '-'))" -%}
{%- set no_date = "regexp_replace(" ~ base ~ ", '-[0-9]{8}$', '')" -%}
{%- set no_family = "regexp_replace(" ~ no_date ~ ", 'opus|sonnet|haiku|fable', '')" -%}
{%- set no_prefix = "regexp_replace(" ~ no_family ~ ", '^claude-', '')" -%}
{%- set version = "regexp_replace(regexp_replace(" ~ no_prefix ~ ", '^-+', ''), '-+$', '')" -%}

    case
        -- old format: claude-{major}[-{minor}]-{family}[-{date}], e.g. claude-3-opus, claude-3-5-sonnet-20240620
        -- new format: claude-{family}-{major}[-{minor}][-{date}], e.g. claude-opus-4-1-20250805, claude-opus-5
        -- either way, stripping the date, the family name and the "claude-" prefix leaves just the version digits
        when lower({{ field }}) not like 'claude-%' then null
        when {{ version }} = '' then null
        else replace({{ version }}, '-', '.')
    end

{% endmacro %}
