# Exercise 2: First Models — CTEs and the ref() Tag - Answers

## Question 1: Why do staging models (`src_*`) never contain joins between tables?

Staging models follow the principle of **one model per source table**. Their only job is to clean, rename, and cast columns from a single raw source — no business logic, no joins. This keeps them simple, reusable, and easy to debug. If a staging model joined multiple tables, it would mix responsibilities: you wouldn't know whether a bug came from the cleaning logic or the join logic. By keeping joins out of the staging layer and pushing them to the mart layer (like `fct_listings`), each staging model can be independently tested and reused by multiple downstream models without carrying unwanted dependencies.

## Question 2: What happens if you rename `raw_listings.csv` to something else without updating `src_listings.sql`?

`dbt seed` will load the renamed CSV under its new filename (e.g., `listings_data.csv` becomes a table called `listings_data`). However, `src_listings.sql` still contains `{{ ref('raw_listings') }}`, which expects a seed or model named `raw_listings`. When you run `dbt run`, dbt will fail with a **compilation error** saying that the model `raw_listings` was not found. The `ref()` function resolves names at compile time based on the dbt project's manifest — if no seed or model matches that name, the DAG cannot be built and execution stops before any SQL is sent to the database.

## Question 3: `fct_listings` uses `LEFT JOIN`. What rows would be lost with an `INNER JOIN`?

With a `LEFT JOIN`, all listings are kept even if they have no matching host. With an `INNER JOIN`, any listing whose `host_id` does not match an `id` in `src_hosts` would be dropped from the results. In our current dataset every listing has a valid host (host IDs 101–104 all exist in `raw_hosts`), so no rows would actually be lost right now. However, if a new listing were added with a `host_id` that doesn't exist in `raw_hosts` (e.g., host 999), the `LEFT JOIN` would still include that listing with NULL host columns, while the `INNER JOIN` would silently exclude it — potentially causing data loss that is hard to detect downstream.
