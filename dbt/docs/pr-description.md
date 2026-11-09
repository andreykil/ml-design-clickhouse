Проект dbt.

Версии: dbt-core 1.10.21, dbt-clickhouse 1.9.8, ClickHouse 25.8.33.6.

Витрины:

- `mart_daily_state_metrics` — дневные метрики по штатам;
- `mart_fraud_by_category` — фрод по категориям;
- `mart_fraud_by_state` — фрод по штатам;
- `mart_customer_risk_profile` — профиль риска клиентов.

Используются макрос `amount_bucket` и пакеты `dbt_utils`, `dbt_date`, `dbt_expectations`.
В YAML описаны модели и колонки, настроены `not_null`, `unique`, `accepted_values`, `relationships`, уникальность комбинаций ключей и проверки диапазонов.
Пять singular tests проверяют отрицательные суммы, границы fraud_rate, сохранение итогов исходных данных и витрин, правила риска клиентов.

Проверка на всех 786 431 транзакциях: `dbt seed`, `dbt run`, `dbt test`, `dbt docs generate` выполнены успешно.
Результат тестов: **PASS=46 WARN=0 ERROR=0 SKIP=0**.
Итоги дополнительно сверены с CSV: 4 504 случая фрода, общая сумма 55 239 932,49.

Скриншот и логи: `dbt/docs/dbt-test.log` и `dbt/docs/dbt-dag.png`.
