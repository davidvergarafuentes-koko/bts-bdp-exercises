# Exercise 4 - Dynamic DAG with YAML Configuration: Questions

## 1. Why did we merge fetch + upload into a single task?

In previous exercises, fetching from the API and uploading to S3 were two separate tasks. The fetch task saved a file locally, passed the file path via XCom, and then a second task read that file and uploaded it to S3. Merging them into `fetch_and_upload` brings several advantages:

- **No local filesystem dependency:** The data goes directly from the API response into S3 via `s3.put_object()`, without writing a temporary file to disk. This is cleaner and avoids issues with disk space, file cleanup, or workers not sharing the same filesystem.
- **Less XCom overhead:** Instead of passing a local file path (which only works if the next task runs on the same machine), we pass an S3 key — a portable, location-independent reference.
- **Simpler DAG:** Fewer tasks means fewer nodes in the graph, less scheduling overhead, and an easier-to-read pipeline. Since the fetch and upload are tightly coupled (there's no reason to upload without fetching first, or vice versa), combining them into one unit of work is a natural fit.
- **Better for dynamic generation:** With a loop creating tasks per source, having 2 tasks per source instead of 3 keeps the DAG compact and reduces boilerplate.

## 2. What are the trade-offs of reading configuration from a YAML file vs hardcoding?

**Advantages of YAML configuration:**

- **Separation of concerns:** The DAG logic (how to process) is separated from the data sources (what to process). A data engineer can add a new source by editing the YAML file without touching Python code.
- **Scalability:** Adding a 10th source is the same effort as adding the 3rd — just a few lines in the YAML. With hardcoding, you'd need to copy-paste functions and wire up dependencies each time.
- **Reduced risk of bugs:** Since the DAG code is not modified when adding sources, there's no risk of accidentally breaking existing pipelines.
- **Reviewability:** Changes to sources show up as clean YAML diffs, not Python code changes.

**Disadvantages / trade-offs:**

- **Less flexibility per source:** If one source needs custom transformation logic (e.g., special parsing, authentication, pagination), a generic config-driven approach can't handle it without adding complexity to the YAML schema or the DAG code.
- **Harder to debug:** If a dynamically generated task fails, it can be less obvious which config entry caused the issue compared to a named, hardcoded function.
- **DAG parsing dependency:** The YAML file must be present and valid when Airflow parses the DAG file. A syntax error in the YAML breaks the entire DAG, not just one source.
- **Hidden complexity:** New team members need to understand that tasks are generated dynamically — the code doesn't show explicit task names, which can make onboarding harder.

## 3. Is this DAG idempotent? What would happen if you trigger it twice for the same date?

Yes, this DAG is **idempotent**. If triggered twice for the same date (`ds`):

- The `fetch_and_upload` task writes to the S3 key `{source_name}/_created_date={ds}/dump.json`. Running it again with the same `ds` overwrites the exact same key with fresh data from the API. The `s3.put_object()` call is an upsert — it creates or replaces the object.
- The `to_silver` task writes to `{source_name}/_created_date={ds}/data.snappy.parquet`, which again overwrites the same key.

The result is that after two runs for the same date, the bronze and silver layers contain exactly the data from the most recent run — no duplicates, no leftover files from the first run. This is the expected behavior for an idempotent pipeline: running it N times produces the same end state as running it once.

This works because the S3 keys are deterministic (based on `ds` and `source_name`), and S3 `put_object` replaces existing objects.

## 4. How would you add error handling for APIs that are down?

Several strategies, from simplest to most robust:

**1. Leverage Airflow retries (already configured):**
The DAG already sets `"retries": 1` in `default_args`. You can increase this and add a delay:
```python
default_args={
    "retries": 3,
    "retry_delay": timedelta(minutes=2),
}
```
This handles transient failures (timeouts, 503s) automatically.

**2. Add HTTP status checking in the task:**
```python
response = requests.get(url, timeout=30)
response.raise_for_status()  # Raises an exception for 4xx/5xx
```
This ensures the task fails explicitly (and triggers a retry) instead of silently processing an error page as data.

**3. Use `trigger_rule` to isolate failures:**
If one source is down, the other pipelines still succeed. This already works because the pipelines are independent. However, you could add alerting per source by adding a downstream notification task with `trigger_rule="one_failed"`.

**4. Add a circuit breaker / fallback:**
For critical pipelines, you could check if the API is reachable before fetching, or skip the source gracefully and log a warning instead of failing the entire DAG run. Airflow's `AirflowSkipException` can mark a task as skipped rather than failed.
