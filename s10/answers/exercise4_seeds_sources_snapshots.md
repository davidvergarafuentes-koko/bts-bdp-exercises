# Exercise 4: Seeds, Sources, and Snapshots — Answers

## Question 1
**What is the difference between calling `source('airbnb_raw', 'raw_listings')` and `ref('raw_listings')`? When would you use each?**

`ref('raw_listings')` references a dbt-managed object (a model or seed) — dbt knows it created that table and tracks it in the DAG. `source('airbnb_raw', 'raw_listings')` references an external table that exists in the database but was not created by dbt (e.g., loaded by an ELT tool like Airflow or Fivetran).

Use `ref()` when pointing to another dbt model or seed. Use `source()` when pointing to raw tables loaded by an external pipeline. In production, raw data tables should always be declared as sources so dbt can track lineage and check freshness.

## Question 2
**A snapshot uses `strategy='check'` and `check_cols=['is_superhost', 'name']`. How is this different from `strategy='timestamp'`? When is it useful?**

With `strategy='timestamp'`, dbt detects changes by comparing the `updated_at` column between runs — if the timestamp changed, the row is considered updated. With `strategy='check'`, dbt compares the actual values of the specified columns (`is_superhost`, `name`) between runs — if any of those values changed, a new snapshot row is inserted.

`strategy='check'` is useful when the source table does not have a reliable `updated_at` timestamp column, or when you only care about changes to specific columns and want to ignore changes to other columns.

## Question 3
**A junior analyst runs `UPDATE snap_hosts SET is_superhost = true WHERE host_id = 104` directly in the database. What problem does this create?**

This breaks the integrity of the snapshot table. Snapshots are managed exclusively by dbt — they rely on `dbt_valid_from` and `dbt_valid_to` to maintain an accurate history of changes. A direct UPDATE bypasses this mechanism: it overwrites the current value without closing the old record or creating a new historical row. The next time `dbt snapshot` runs, dbt will not detect any change (since the source table was not modified), so the history will be inconsistent — the snapshot will show a value that never actually existed in the source data. The audit trail is corrupted and you can no longer trust historical queries against this table.

## Question 4
**How would you use `snap_hosts` in a downstream mart model to always see the current state of each host?**

Filter the snapshot table for rows where `dbt_valid_to IS NULL` — these represent the current (most recent) version of each record:

```sql
SELECT
    host_id,
    host_name,
    is_superhost,
    dbt_valid_from
FROM {{ ref('snap_hosts') }}
WHERE dbt_valid_to IS NULL
```

This can be used as a CTE or joined into a mart model to always get the latest state of each host while still preserving the full history in the snapshot table for time-travel queries.
