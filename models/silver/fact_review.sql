{{ config(materialized='table') }}

with base as (
    select
    listing_id,
    month_date,
    scraped_date,
    review_scores_rating,
    review_scores_accuracy,
    review_scores_cleanliness,
    review_scores_checkin,
    review_scores_communication,
    review_scores_value,
    row_number() over (
    partition by listing_id, month_date
    order by scraped_date desc nulls last
    ) as rn
    from {{ ref('airbnb_listing') }}
)

select
{{ dbt_utils.generate_surrogate_key(['listing_id','month_date::text']) }} as review_month_id,
listing_id, month_date, scraped_date, review_scores_rating, review_scores_accuracy,
review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_value
from base
where rn = 1