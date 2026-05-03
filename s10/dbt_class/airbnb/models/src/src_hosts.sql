WITH raw AS (
    SELECT * FROM {{ source('airbnb_raw', 'raw_hosts') }}
)

SELECT
    id                              AS host_id,
    name                            AS host_name,
    CASE WHEN is_superhost = 't' THEN TRUE
         ELSE FALSE END             AS is_superhost,
    CAST(created_at AS DATE)        AS created_at,
    CAST(updated_at AS DATE)        AS updated_at
FROM raw
