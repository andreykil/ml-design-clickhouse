{# Макрос делит суммы покупок на сегменты SMALL, MEDIUM и LARGE. #}
{% macro amount_bucket(column) %}
    case
        when {{ column }} < 100 then 'SMALL'
        when {{ column }} < {{ var('large_amount_threshold') }} then 'MEDIUM'
        else 'LARGE'
    end
{% endmacro %}
