-- Проверка, что подготовка данных сохранила число транзакций, суммы и число фродов.
with raw_totals as (
    select count() as row_count, sum(amount) as total_amount, sum(target) as fraud_count
    from {{ source('transactions_db', 'transactions') }}
), staging_totals as (
    select count() as row_count, sum(amount) as total_amount, sum(is_fraud) as fraud_count
    from {{ ref('stg_transactions') }}
)

select raw_totals.row_count, staging_totals.row_count
from raw_totals
cross join staging_totals
where raw_totals.row_count != staging_totals.row_count
    or abs(raw_totals.total_amount - staging_totals.total_amount) > 0.01
    or raw_totals.fraud_count != staging_totals.fraud_count
