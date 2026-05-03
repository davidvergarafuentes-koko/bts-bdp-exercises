{{ config(materialized='table') }}

WITH enriched AS (
    SELECT * FROM {{ ref('_int_listing_with_host') }}
)

SELECT
    listing_id,
    listing_name,
    neighbourhood,
    room_type,
    price_usd,
    host_name,
    is_superhost
FROM enriched
