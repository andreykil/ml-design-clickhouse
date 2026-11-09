-- Проверка, что fraud_rate во всех витринах конечен и находится в пределах 0–100%.
{% for model in ['mart_fraud_by_category', 'mart_fraud_by_state', 'mart_customer_risk_profile'] %}
select '{{ model }}' as model_name, fraud_rate
from {{ ref(model) }}
where fraud_rate < 0 or fraud_rate > 100 or not isFinite(fraud_rate)
{% if not loop.last %}union all{% endif %}
{% endfor %}
