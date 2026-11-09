-- Витрина фрода по штатам с количеством клиентов и мерчантов.
with metrics as (
    select
        state_code,
        count() as transaction_count,
        countIf(is_fraud = 1) as fraud_count,
        100.0 * countIf(is_fraud = 1) / count() as fraud_rate,
        uniqExact(customer_id) as customer_count,
        uniqExact(merchant) as merchant_count,
        sum(amount) as total_amount,
        sumIf(amount, is_fraud = 1) as fraud_amount
    from {{ ref('stg_transactions') }}
    group by state_code
)

select
    metrics.*,
    states.state_name
from metrics
left join {{ ref('states') }} as states on metrics.state_code = states.state_code
