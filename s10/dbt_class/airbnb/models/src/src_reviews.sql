WITH raw AS (
    SELECT * FROM {{ source('airbnb_raw', 'raw_reviews') }}
)

SELECT
    listing_id,
    reviewer_name,
    CAST(rating AS INTEGER)         AS rating,
    CAST(review_date AS DATE)       AS review_date
FROM raw
