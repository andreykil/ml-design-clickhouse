-- Подготовка исходных транзакций: типы, строки, ключ клиента и вычисляемые поля.
with normalized as (
    select
        transaction_id,
        cast(transaction_time as DateTime('UTC')) as transaction_time,
        trimBoth(merch) as merchant,
        lowerUTF8(trimBoth(cat_id)) as category,
        cast(amount as Float64) as amount,
        trimBoth(name_1) as first_name,
        trimBoth(name_2) as last_name,
        upperUTF8(trimBoth(gender)) as gender,
        upperUTF8(trimBoth(us_state)) as state_code,
        trimBoth(street) as street,
        trimBoth(post_code) as post_code,
        cast(lat as Float64) as lat,
        cast(lon as Float64) as lon,
        cast(merchant_lat as Float64) as merchant_lat,
        cast(merchant_lon as Float64) as merchant_lon,
        cast(target as UInt8) as is_fraud
    from {{ source('transactions_db', 'transactions') }}
)

select
    *,
    toDate(transaction_time) as transaction_date,
    toHour(transaction_time) as transaction_hour,
    {{ dbt_date.day_of_week('transaction_time') }} as day_of_week,
    -- Имя и адрес дают ключ клиента, отдельного ID в данных нет.
    {{ dbt_utils.generate_surrogate_key(['first_name', 'last_name', 'street', 'post_code']) }} as customer_id,
    {{ amount_bucket('amount') }} as amount_bucket,
    amount >= {{ var('large_amount_threshold') }} as is_large
from normalized
