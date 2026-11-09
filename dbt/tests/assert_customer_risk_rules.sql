-- Проверка порядка дат и соответствия уровня риска истории фрода клиента.
select customer_id, fraud_rate, risk_level
from {{ ref('mart_customer_risk_profile') }}
where first_transaction_time > last_transaction_time
    or (risk_level = 'HIGH' and fraud_rate < {{ var('high_risk_fraud_rate') }})
    or (risk_level = 'MEDIUM' and (fraud_count = 0 or fraud_rate >= {{ var('high_risk_fraud_rate') }}))
    or (risk_level = 'LOW' and fraud_count != 0)
