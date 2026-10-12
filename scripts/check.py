"""Ждет загрузки всех строк, проверяет ответ и сохраняет CSV."""

import csv
import io
import time
from decimal import Decimal
from pathlib import Path

from common import query


def main() -> None:
    expected = {}
    source_rows = 0
    with Path("data/train.csv").open(newline="", encoding="utf-8") as file:
        for row in csv.DictReader(file):
            source_rows += 1
            state = row["us_state"]
            candidate = (Decimal(row["amount"]), row["cat_id"])
            if state not in expected or candidate > expected[state]:
                expected[state] = candidate

    deadline = time.monotonic() + 180
    while True:
        actual_rows = int(query("SELECT count() FROM fraud.transactions"))
        if actual_rows == source_rows:
            break
        if actual_rows > source_rows or time.monotonic() >= deadline:
            raise RuntimeError(f"Ожидалось {source_rows} строк, в ClickHouse {actual_rows}.")
        print(f"Ждем ClickHouse: {actual_rows:,} / {source_rows:,}")
        time.sleep(2)

    result = query(Path("sql/02_max_transaction_by_state.sql").read_text(encoding="utf-8"))
    records = list(csv.DictReader(io.StringIO(result)))
    actual = {
        row["us_state"]: (Decimal(row["max_amount"]), row["cat_id"])
        for row in records
    }
    if actual != expected or len(records) != len(expected):
        raise RuntimeError("Результат SQL не совпадает с расчетом по исходному CSV.")
    output = Path("results/max_transaction_by_state.csv")
    output.parent.mkdir(exist_ok=True)
    output.write_text(result, encoding="utf-8")
    print(f"OK: {actual_rows:,} транзакций, {len(records)} штатов; ответ совпадает с CSV.")
    print(f"Результат: {output}")


if __name__ == "__main__":
    main()
