# Exercise 3: Materializations — Answers

## Question 1: A model is queried 10,000 times per day. Which materialization is best?

**Table**. A view re-executes the underlying SQL every time it is queried, so 10,000 queries per day means 10,000 full computations. A table materializes the result once during `dbt run`, and all 10,000 queries read from the pre-computed physical table — dramatically reducing database load and improving query response time.

## Question 2: A model processes a 1 TB event log and only 0.1% of rows are new each run. Which materialization saves the most compute cost?

**Incremental**. A full table rebuild would reprocess all 1 TB every run, even though 99.9% of the data hasn't changed. An incremental model uses a filter (e.g., `WHERE event_date > (SELECT MAX(event_date) FROM {{ this }})`) to process only the ~1 GB of new rows, saving roughly 99.9% of compute cost on each subsequent run.

## Question 3: You change a column name in an incremental model. Why must you run `--full-refresh`?

Because the existing table in the database still has the old column name. On a normal incremental run, dbt tries to `INSERT` new rows into the existing table — but the column names no longer match, causing the insert to fail or produce incorrect results. Running `dbt run --full-refresh` drops the existing table and rebuilds it from scratch with the new schema, ensuring the column rename is applied to the entire dataset.

## Question 4: Can an ephemeral model be referenced by more than one downstream model? What is the tradeoff?

Yes, an ephemeral model can be referenced by multiple downstream models using `{{ ref() }}`. However, the tradeoff is that dbt **inlines the full SQL as a CTE** in every model that references it. This means the same query logic is duplicated and executed independently in each downstream model. If the ephemeral model's logic is expensive (e.g., a heavy join or aggregation), it will be computed multiple times — once per downstream consumer — instead of once. In that case, materializing it as a `view` or `table` would be more efficient because the computation happens only once and the result is shared.
