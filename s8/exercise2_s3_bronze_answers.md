# Exercise 2 - Upload to S3 Bronze Layer: Questions

## 1. What is `ds` in the task signature? Where does it come from?

`ds` is an **Airflow template variable** that represents the **logical execution date** of the DAG run in `YYYY-MM-DD` format (e.g., `2026-03-20`).

It is automatically injected by Airflow when you include it as a parameter in a `@task` function signature — you don't need to pass it manually. Airflow recognizes `ds` as a reserved keyword and fills it in with the DAG run's data interval start date.

In the code, it's used to partition the S3 path by date:

```python
s3_key = f"chuck_jokes/_created_date={ds}/dump.json"
# Result: chuck_jokes/_created_date=2026-03-20/dump.json
```

## 2. What would happen if you used `datetime.now().strftime("%Y-%m-%d")` instead of `ds`?

Two problems:

- **Non-deterministic paths:** `datetime.now()` returns the actual wall-clock time when the task executes, not the scheduled logical date. If a DAG run is delayed, retried, or backfilled, the date in the S3 path would reflect when it actually ran, not when it was supposed to run. For example, a DAG scheduled for March 20th but retried on March 21st would incorrectly write to `_created_date=2026-03-21/`.

- **Breaks idempotency:** If you re-run the same DAG run (e.g., via "Clear" in the UI), `datetime.now()` could produce a different date, creating duplicate data in a different folder instead of overwriting the original.

Using `ds` ensures the path is always tied to the logical schedule, regardless of when the task actually executes.

## 3. How does XCom pass `local_path` between tasks?

XCom (Cross-Communication) works in three steps:

1. **`fetch_api()` runs** and returns `"/tmp/chuck_jokes.json"`. Airflow automatically stores this return value in its metadata database as an XCom entry.

2. **Task dependency is established** by writing `local_file = fetch_api()` and passing it to `upload_to_s3(local_file)`. This tells Airflow that `upload_to_s3` depends on `fetch_api`.

3. **`upload_to_s3(local_path)` runs** and Airflow automatically pulls the stored XCom value and passes it as the `local_path` parameter. The task receives `"/tmp/chuck_jokes.json"` as input.

Important: XCom transfers only the **small metadata** (the file path string), not the actual file contents. The file itself stays on disk at `/tmp/chuck_jokes.json` and both tasks access it via the shared filesystem.

## 4. Is this pipeline idempotent? Why or why not?

**Yes, this pipeline is idempotent.** Running the same DAG run multiple times produces the same result because:

- **Same API call:** `fetch_api()` always fetches the same endpoint and overwrites `/tmp/chuck_jokes.json`.
- **Same S3 key:** The upload path `chuck_jokes/_created_date={ds}/dump.json` is determined by `ds`, which is fixed for a given DAG run. Re-running it overwrites the same S3 object with the same data.
- **No side effects accumulate:** There are no append operations or auto-incrementing keys — each run fully replaces the previous output for that date.

This means you can safely "Clear" and re-run a DAG run without creating duplicates or corrupting data.
