-- Витрина истории транзакций и уровня риска каждого клиента.
with customer_metrics as (
    select
        customer_id,
        min(transaction_time) as first_transaction_time,
        max(transaction_time) as last_transaction_time,
        count() as transaction_count,
        countIf(is_fraud = 1) as fraud_count,
        100.0 * countIf(is_fraud = 1) / count() as fraud_rate,
        sum(amount) as total_amount,
        sumIf(amount, is_fraud = 1) as fraud_amount,
        avg(amount) as avg_amount
    from {{ ref('stg_transactions') }}
    group by customer_id
)

select
    *,
    -- Это учебное правило сегментации по истории, а не прогноз будущего фрода.
    case
        when fraud_rate >= {{ var('high_risk_fraud_rate') }} then 'HIGH'
        when fraud_count > 0 then 'MEDIUM'
        else 'LOW'
    end as risk_level
from customer_metrics
