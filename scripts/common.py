"""Небольшой HTTP-клиент ClickHouse для загрузчика и проверки."""

import os

import requests


def query(sql: str, **params) -> str:
    response = requests.post(
        os.getenv("CLICKHOUSE_URL", "http://localhost:8123"),
        auth=(
            os.getenv("CLICKHOUSE_USER", "student"),
            os.getenv("CLICKHOUSE_PASSWORD", "homework"),
        ),
        params=params,
        data=sql.encode("utf-8"),
        timeout=300,
    )
    if not response.ok:
        raise RuntimeError(response.text)
    return response.text
