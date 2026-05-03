# Exercise 1: dbt Setup and Project Structure - Answers

## Question 1: Why does `profiles.yml` live in `~/.dbt/` and not inside the project folder?

Because `profiles.yml` contains connection credentials (database host, username, password, tokens, etc.) that are sensitive and should never be committed to version control. By keeping it outside the project directory in `~/.dbt/`, the project folder can be safely pushed to Git without risking credential exposure. It also allows each developer or environment (dev, CI, production) to have its own connection settings without modifying the shared project code.

In our setup, `~/.dbt/profiles.yml` contains:

```yaml
airbnb:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: "airbnb.duckdb"
      threads: 4
```

## Question 2: What is the difference between `target/compiled/` and `target/run/`?

- **`target/compiled/`** contains the pure SQL after Jinja has been resolved, but without any DDL wrapping. It shows exactly what the query logic looks like after template rendering. For example, `my_second_dbt_model.sql` in compiled becomes:

  ```sql
  select *
  from "airbnb"."main"."my_first_dbt_model"
  where id = 1
  ```

- **`target/run/`** contains the full SQL that was actually executed against the database, including the DDL statements (CREATE VIEW, CREATE TABLE, etc.) that dbt wraps around the compiled query. For example, the same model in run becomes:

  ```sql
  create view "airbnb"."main"."my_second_dbt_model__dbt_tmp" as (
    select *
    from "airbnb"."main"."my_first_dbt_model"
    where id = 1
  );
  ```

In short: **compiled = resolved query logic**, **run = full executable DDL sent to the database**.

## Question 3: If `my_second_model` depends on `my_first_model`, what happens when you run `dbt run --select my_second_model` without running `my_first_model` first?

dbt will only build `my_second_model` and will **not** automatically run `my_first_model`, because `--select` restricts execution to only the specified model. What happens next depends on whether `my_first_model` already exists in the database:

- **If `my_first_model` was previously run and exists** (as a view or table in DuckDB): the command succeeds, because the `ref('my_first_dbt_model')` resolves to an existing database object that can be queried.
- **If `my_first_model` was never run and does not exist**: the command fails with a database error because the referenced view/table does not exist.

To include upstream dependencies automatically, you would use the `+` prefix: `dbt run --select +my_second_model`, which tells dbt to also build all ancestors in the DAG.
