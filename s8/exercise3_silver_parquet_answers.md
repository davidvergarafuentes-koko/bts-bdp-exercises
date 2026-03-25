# Exercise 3 - Bronze to Silver with Parquet: Questions

## 1. Why is Parquet better than JSON for the silver layer?

Parquet is superior for analytics workloads for several reasons:

- **Columnar storage:** Data is stored by column, not by row. Analytical queries that only need a few columns (e.g., `SELECT id, value FROM ...`) can skip reading the rest, making them much faster.
- **Schema enforcement:** Parquet files embed a typed schema (integers, strings, timestamps, etc.), whereas JSON stores everything as text. This catches data type issues early.
- **Compression:** Columnar layout compresses much better because similar values are stored together. A column of dates compresses far more efficiently than rows of mixed types.
- **Smaller file size:** The combination of columnar format + compression means Parquet files are typically 5-10x smaller than equivalent JSON.
- **Native support in analytics tools:** Spark, DuckDB, Pandas, Athena, BigQuery, etc. all read Parquet natively and efficiently.

JSON is fine for bronze (raw ingestion, human-readable), but silver is meant for clean, optimized data — and Parquet is the standard format for that.

## 2. What does `compression="snappy"` do?

Snappy is a **compression algorithm** developed by Google that prioritizes **speed over compression ratio**. When applied to a Parquet file:

- It compresses each column's data blocks, reducing file size (typically 2-4x smaller).
- It is very fast to decompress, which matters when reading large datasets in analytics queries.
- The tradeoff: Snappy doesn't compress as tightly as gzip or zstd, but it decompresses significantly faster.

This is why the output file is named `data.snappy.parquet` — the `.snappy` indicates the compression codec used. Snappy is the most common default for Parquet files in data engineering.

## 3. How does Airflow know the two pipelines can run in parallel?

Airflow builds a **dependency graph (DAG)** by analyzing the data flow between tasks. It looks at which task outputs feed into which task inputs:

```python
# Pipeline 1: Chuck Jokes
local_file = fetch_api()
s3_key = upload_to_s3(local_file)
bronze_to_silver(s3_key)

# Pipeline 2: Universities
uni_file = fetch_universities()
uni_s3_key = upload_universities_to_s3(uni_file)
universities_bronze_to_silver(uni_s3_key)
```

Since Pipeline 2 does **not depend on any output from Pipeline 1** (and vice versa), Airflow sees them as two independent chains with no XCom links between them. It can therefore schedule `fetch_api()` and `fetch_universities()` to start at the same time, without waiting for one to finish before starting the other.

Within each pipeline, tasks still run sequentially (upload waits for fetch, silver waits for upload) because each task depends on the previous task's return value via XCom.

## 4. What would the Graph view look like?

The Graph view would show **two parallel chains** side by side:

```
fetch_api  ──>  upload_to_s3  ──>  bronze_to_silver

fetch_universities  ──>  upload_universities_to_s3  ──>  universities_bronze_to_silver
```

Both chains start from the left with no shared root and no connections between them. This visually confirms that the two pipelines are independent and can execute in parallel. Each chain shows three nodes connected by arrows representing the XCom dependencies.
