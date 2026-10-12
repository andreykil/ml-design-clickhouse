-- Категория самой большой отдельной транзакции в каждом штате
-- При равных суммах выбираем категорию, последнюю по алфавиту
SELECT
    us_state,
    argMax(cat_id, tuple(amount, cat_id)) AS cat_id,
    max(amount) AS max_amount
FROM fraud.transactions
GROUP BY us_state
ORDER BY us_state
FORMAT CSVWithNames;
