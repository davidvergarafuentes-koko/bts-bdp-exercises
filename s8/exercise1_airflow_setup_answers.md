# Exercise 1 - Airflow Setup: Questions

## 1. What happens if the API is down when the DAG runs?

The `requests.get()` call in the `fetch_api` task will either:

- **Raise a `ConnectionError`** if the API server is unreachable (DNS failure, server offline).
- **Raise a `Timeout` error** if the server doesn't respond in time.
- **Return an HTTP error status** (e.g., 500, 503), in which case `response.json()` may fail or return unexpected data.

In all these cases, the task will be marked as **failed** in Airflow. The DAG run will also be marked as failed, and the error will be visible in the Airflow UI logs. No file will be written (or the existing file won't be updated).

## 2. How would you configure automatic retries?

You can add `retries` and `retry_delay` parameters either at the **DAG level** (via `default_args`) or at the **task level**:

**Option A: DAG-level default args (applies to all tasks)**

```python
from datetime import timedelta

default_args = {
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="exercise1_api",
    start_date=datetime(2026, 1, 1),
    schedule="0 14 * * *",
    catchup=False,
    default_args=default_args,
) as dag:
    ...
```

**Option B: Task-level (applies to a specific task)**

```python
@task(retries=3, retry_delay=timedelta(minutes=5))
def fetch_api():
    ...
```

With this configuration, if the task fails, Airflow will automatically retry it up to 3 times, waiting 5 minutes between each attempt.

## 3. Why is `catchup=False` important?

When `catchup=False` is set, Airflow will **only run the most recent scheduled DAG run** when the DAG is first enabled or after a pause.

Without it (`catchup=True` by default), Airflow would try to **backfill all missed runs** between the `start_date` and now. For example, with `start_date=datetime(2026, 1, 1)` and a daily schedule, enabling the DAG on March 21st would trigger **~80 DAG runs** to catch up on all the missed days.

This is problematic because:

- It floods the scheduler with dozens of queued runs.
- It makes unnecessary API calls (hitting rate limits or overloading the external service).
- The historical data may not even be relevant since the API returns the same results regardless of date.

Setting `catchup=False` avoids all of this and only schedules from the current time forward.
