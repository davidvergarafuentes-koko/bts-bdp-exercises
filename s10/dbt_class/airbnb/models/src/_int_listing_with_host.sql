{{ config(materialized='ephemeral') }}

WITH listings AS (
    SELECT * FROM {{ ref('src_listings') }}
),

hosts AS (
    SELECT * FROM {{ ref('src_hosts') }}
)

SELECT
    l.listing_id,
    l.listing_name,
    l.neighbourhood,
    l.room_type,
    l.price_usd,
    h.host_name,
    h.is_superhost
FROM listings l
LEFT JOIN hosts h ON l.host_id = h.host_id
