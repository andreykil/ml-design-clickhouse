{# Адаптация расчета дня недели из dbt_date для ClickHouse. #}
{% macro clickhouse__day_of_week(date, isoweek) %}
    {% if isoweek %}
        toDayOfWeek({{ date }})
    {% else %}
        toDayOfWeek({{ date }}) % 7 + 1
    {% endif %}
{% endmacro %}
