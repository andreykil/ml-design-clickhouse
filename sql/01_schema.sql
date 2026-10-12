CREATE DATABASE IF NOT EXISTS fraud;

CREATE TABLE IF NOT EXISTS fraud.transactions
(
    transaction_time DateTime CODEC(ZSTD(1)),
    merch LowCardinality(String) CODEC(ZSTD(1)),
    cat_id LowCardinality(String) CODEC(LZ4),
    amount Decimal(12, 2) CODEC(LZ4),
    name_1 String CODEC(ZSTD(1)),
    name_2 String CODEC(ZSTD(1)),
    gender LowCardinality(String) CODEC(ZSTD(1)),
    street String CODEC(ZSTD(1)),
    one_city String CODEC(ZSTD(1)),
    us_state LowCardinality(String) CODEC(LZ4),
    post_code String CODEC(ZSTD(1)),
    lat Float64 CODEC(ZSTD(1)),
    lon Float64 CODEC(ZSTD(1)),
    population_city UInt32 CODEC(ZSTD(1)),
    jobs LowCardinality(String) CODEC(ZSTD(1)),
    merchant_lat Float64 CODEC(ZSTD(1)),
    merchant_lon Float64 CODEC(ZSTD(1)),
    target UInt8 CODEC(ZSTD(1))
)
ENGINE = MergeTree
ORDER BY (us_state, cat_id);

CREATE TABLE IF NOT EXISTS fraud.transactions_kafka
(
    transaction_time DateTime,
    merch String,
    cat_id String,
    amount Decimal(12, 2),
    name_1 String,
    name_2 String,
    gender String,
    street String,
    one_city String,
    us_state String,
    post_code String,
    lat Float64,
    lon Float64,
    population_city UInt32,
    jobs String,
    merchant_lat Float64,
    merchant_lon Float64,
    target UInt8
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'fraud-transactions-v1',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 1,
    kafka_max_block_size = 65536,
    kafka_flush_interval_ms = 1000;

CREATE MATERIALIZED VIEW IF NOT EXISTS fraud.transactions_consumer
TO fraud.transactions
AS SELECT * FROM fraud.transactions_kafka;
