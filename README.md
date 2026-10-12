# ClickHouse

Проект загружает `data/train.csv` в топик Kafka `transactions`, сохраняет
транзакции в ClickHouse и находит категорию самой большой транзакции для каждого
штата. 

## Запуск

Команды выполняются из папки проекта. Исходный файл должен находиться в `data/train.csv`.

```bash
docker compose up -d --build --wait
docker compose run --rm --build loader
docker compose run --rm loader python scripts/check.py
```

Первая команда поднимает Kafka и Clickhouse и создает топик и таблицы. Вторая
загружает CSV в kafka. Третья проверяет что все строки корректно загрузились, выполняет запрос и сохраняет получившийся CSV в `results/max_transaction_by_state.csv`.

## Запрос и результат

Запрос находится в `sql/02_max_transaction_by_state.sql`. Он возвращает
`us_state`, `cat_id` и `max_amount`. При равных максимальных
суммах выбирается категория, последняя по алфавиту, результат отсортирован по штату.

```sql
SELECT
    us_state,
    argMax(cat_id, tuple(amount, cat_id)) AS cat_id,
    max(amount) AS max_amount
FROM fraud.transactions
GROUP BY us_state
ORDER BY us_state
FORMAT CSVWithNames;
```

## Оптимизация

- `LowCardinality(String)` для штата, категории, пола, продавца и профессии:
  повторяющиеся строки хранятся через словарь.
- `ORDER BY (us_state, cat_id)`: одинаковые штаты и категории лежат рядом.
- LZ4 для трех колонок запроса (`us_state`, `cat_id`, `amount`), ZSTD(1) для остальных:
  сохраняем скорость запроса и уменьшаем размер таблицы. Размер уменьшился примерно в 2 раза по сравнению с базовой таблицей на LZ4.

Медиана времени запроса: 14 мс

Размер данных таблицы на диске: 26 МБ
