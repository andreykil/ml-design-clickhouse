# Загрузка train.csv в исходную таблицу ClickHouse с добавлением ID транзакции.
import argparse
import csv
import os
from datetime import datetime, timezone
from pathlib import Path

import clickhouse_connect


def main():
    parser = argparse.ArgumentParser(description='Загрузить train.csv в ClickHouse')
    parser.add_argument(
        '--csv', type=Path,
        default=Path(__file__).resolve().parents[2] / 'data/train.csv',
    )
    parser.add_argument(
        '--replace', action='store_true', help='Очистить исходную таблицу перед загрузкой',
    )
    args = parser.parse_args()

    # Проверяем файл до изменения таблицы.
    with args.csv.open(newline='', encoding='utf-8') as source:
        reader = csv.DictReader(source)
        columns = reader.fieldnames
        if not columns or 'target' not in columns:
            parser.error('Нужен train.csv с колонкой target')

    client = clickhouse_connect.get_client(
        host=os.getenv('CLICKHOUSE_HOST', 'localhost'),
        port=int(os.getenv('CLICKHOUSE_PORT', '8123')),
        username=os.getenv('CLICKHOUSE_USER', 'student'),
        password=os.getenv('CLICKHOUSE_PASSWORD', 'homework'),
    )
    try:
        schema = Path(__file__).with_name('schema.sql').read_text(encoding='utf-8')
        for statement in schema.split(';'):
            if statement.strip():
                client.command(statement)

        count = client.command('SELECT count() FROM transactions_db.transactions')
        if count and not args.replace:
            parser.error('Таблица уже заполнена. Для повторной загрузки используйте --replace')
        if args.replace:
            client.command('TRUNCATE TABLE transactions_db.transactions')

        batch = []
        total = 0
        insert_columns = ['transaction_id'] + columns
        float_columns = ['amount', 'lat', 'lon', 'merchant_lat', 'merchant_lon']
        with args.csv.open(newline='', encoding='utf-8') as source:
            for number, row in enumerate(csv.DictReader(source), start=1):
                row['transaction_time'] = datetime.strptime(
                    row['transaction_time'], '%Y-%m-%d %H:%M'
                ).replace(tzinfo=timezone.utc)
                for column in float_columns:
                    row[column] = float(row[column])
                row['target'] = int(row['target'])
                row['population_city'] = int(row['population_city'])
                # В CSV нет ID транзакции: сохраняем номер строки исходного файла.
                batch.append([number] + [row[column] for column in columns])
                if len(batch) == 10000:
                    client.insert('transactions_db.transactions', batch, column_names=insert_columns)
                    total += len(batch)
                    batch = []

        if batch:
            client.insert('transactions_db.transactions', batch, column_names=insert_columns)
            total += len(batch)

        loaded = client.command('SELECT count() FROM transactions_db.transactions')
        if loaded != total:
            raise RuntimeError(f'Ожидалось {total} строк, в таблице {loaded}')
        print(f'Загружено {loaded} транзакций в transactions_db.transactions')
    finally:
        client.close()


if __name__ == '__main__':
    main()
