{{ config(materialized='incremental') }}

WITH reviews AS (
    SELECT * FROM {{ ref('src_reviews') }}
),

daily AS (
    SELECT
        review_date,
        COUNT(*)                        AS total_reviews,
        ROUND(AVG(rating), 2)           AS avg_rating,
        COUNT(CASE WHEN rating = 5
            THEN 1 END)                 AS five_star_count
    FROM reviews
    {% if is_incremental() %}
        WHERE review_date > (SELECT MAX(review_date) FROM {{ this }})
    {% endif %}
    GROUP BY review_date
)

SELECT * FROM daily
