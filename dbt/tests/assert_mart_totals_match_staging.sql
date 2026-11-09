-- Сверка количества транзакций и сумм в витринах с подготовленными данными.
with expected as (
    select
        count() as transaction_count,
        sum(amount) as total_amount,
        countIf(is_fraud = 1) as fraud_count,
        sumIf(amount, is_fraud = 1) as fraud_amount
    from {{ ref('stg_transactions') }}
)

{% for model in ['mart_daily_state_metrics', 'mart_fraud_by_category', 'mart_fraud_by_state', 'mart_customer_risk_profile'] %}
select '{{ model }}' as model_name
from (
    select
        sum(transaction_count) as transaction_count,
        sum(total_amount) as total_amount
        {% if model != 'mart_daily_state_metrics' %}
        , sum(fraud_count) as fraud_count
        , sum(fraud_amount) as fraud_amount
        {% endif %}
    from {{ ref(model) }}
) as actual
cross join expected
where actual.transaction_count != expected.transaction_count
    -- При сложении float64 в разном порядке возможна небольшая погрешность
    or abs(actual.total_amount - expected.total_amount) > 0.01
    {% if model != 'mart_daily_state_metrics' %}
    or actual.fraud_count != expected.fraud_count
    or abs(actual.fraud_amount - expected.fraud_amount) > 0.01
    {% endif %}
{% if not loop.last %}union all{% endif %}
{% endfor %}
