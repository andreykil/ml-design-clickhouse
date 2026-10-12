"""Читает train.csv построчно и отправляет транзакции в Kafka."""

import argparse
import csv
import json
import os
import time
from pathlib import Path

from confluent_kafka import Producer

from common import query


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_file", nargs="?", default="data/train.csv")
    args = parser.parse_args()
    if int(query("SELECT count() FROM fraud.transactions")):
        raise SystemExit(
            "Таблица уже содержит данные. Повторная загрузка создаст дубликаты."
        )

    errors = []

    def delivered(error, message):
        if error:
            errors.append(str(error))

    producer = Producer({
        "bootstrap.servers": os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092"),
        "enable.idempotence": True,
        "acks": "all",
        "linger.ms": 20,
        "compression.type": "lz4",
    })
    count = 0
    started = time.monotonic()
    with Path(args.csv_file).open(newline="", encoding="utf-8") as file:
        reader = csv.DictReader(file)
        if "target" not in (reader.fieldnames or []):
            raise SystemExit("Отсутствует колонка target.")
        for row in reader:
            row["transaction_time"] += ":00"  # В исходном CSV время до минут
            row["population_city"] = int(row["population_city"])
            row["target"] = int(row["target"])
            for column in ("lat", "lon", "merchant_lat", "merchant_lon"):
                row[column] = float(row[column])
            
            payload = json.dumps(row, ensure_ascii=False).encode("utf-8")
            while True:
                try:
                    producer.produce(
                        os.getenv("KAFKA_TOPIC", "transactions"),
                        value=payload,
                        on_delivery=delivered,
                    )
                    break
                except BufferError:
                    producer.poll(0.1)
            producer.poll(0)
            if errors:
                raise RuntimeError(errors[0])
            count += 1
            if count % 100000 == 0:
                print(f"Отправлено {count:,} строк")
    remaining = producer.flush(120)
    if remaining or errors:
        raise RuntimeError(f"Не доставлено: {remaining}; ошибки: {errors[:3]}")
    print(f"Kafka подтвердила доставку {count:,} строк за {time.monotonic() - started:.1f} с.")


if __name__ == "__main__":
    main()
