-- Витрина количества, сумм и распределения покупок по дням и штатам.
select
    transaction_date,
    state_code,
    count() as transaction_count,
    sum(amount) as total_amount,
    avg(amount) as avg_amount,
    quantileExact(0.95)(amount) as p95_amount,
    -- Доли во всех витринах храним в процентах.
    100.0 * countIf(is_large) / count() as large_transaction_share
from {{ ref('stg_transactions') }}
group by transaction_date, state_code
