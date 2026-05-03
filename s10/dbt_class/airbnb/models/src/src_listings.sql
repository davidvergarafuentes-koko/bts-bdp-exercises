WITH raw AS (
    SELECT * FROM {{ source('airbnb_raw', 'raw_listings') }}
)

SELECT
    id                              AS listing_id,
    name                            AS listing_name,
    host_id,
    neighbourhood,
    room_type,
    minimum_nights,
    CAST(price AS DECIMAL(10, 2))   AS price_usd,
    CAST(created_at AS DATE)        AS created_at,
    CAST(updated_at AS DATE)        AS updated_at
FROM raw
