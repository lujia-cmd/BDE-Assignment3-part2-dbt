{{ config(
  materialized='incremental',
  unique_key='listing_month_id',
  incremental_strategy='delete+insert'
) }}

with del as (
    select
    regexp_replace("SCRAPED_DATE", '[^\x09\x0A\x0D\x20-\x7E]', '', 'g') as scraped_date_raw,
    regexp_replace(trim("PRICE"),  '[^\x09\x0A\x0D\x20-\x7E]', '', 'g') as price_raw,
    regexp_replace(trim("HAS_AVAILABILITY"), '[^\x20-\x7E]', '', 'g') as has_availability_raw,
    regexp_replace(trim("HOST_IS_SUPERHOST"), '[^\x20-\x7E]', '', 'g') as host_is_superhost_raw,
    *
    from {{ source('bronze','airbnb_052020') }}
),

deal as (
    select
    -- Timestamp: YYYY-MM-DD HH:MM:SS or YYYY-MM-DD
    case
    when scraped_date_raw ~ '^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}$'
    then to_timestamp(scraped_date_raw,'YYYY-MM-DD HH24:MI:SS')
    when scraped_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
    then to_timestamp(scraped_date_raw,'YYYY-MM-DD')
    else null
    end as scraped_date,

    date_trunc('month',
    case
    when scraped_date_raw ~ '^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}$'
    then to_timestamp(scraped_date_raw,'YYYY-MM-DD HH24:MI:SS')
    when scraped_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
    then to_timestamp(scraped_date_raw,'YYYY-MM-DD')
    else null
    end
    )::date as month_date,

    --Price Cleaning
    case
    when price_raw ~ '^\d+(\.\d+)?$'
    then price_raw::numeric(12,2)
    when regexp_replace(price_raw,'[^0-9\.]','','g') ~ '^\d+(\.\d+)?$'
    then regexp_replace(price_raw,'[^0-9\.]','','g')::numeric(12,2)
    else null
    end as price,

    --Bool
    case
    when lower(has_availability_raw) = 't' then true
    when lower(has_availability_raw) = 'f' then false
    else null
    end as has_availability,

    case
    when lower(host_is_superhost_raw) = 't' then true
    when lower(host_is_superhost_raw) = 'f' then false
    else null
    end as host_is_superhost,

    --Numeric standard
    nullif(nullif(lower(trim("ACCOMMODATES")), 'null'), '')::int as accommodates,
    nullif(nullif(lower(trim("AVAILABILITY_30")), 'null'), '')::int as availability_30,
    nullif(nullif(lower(trim("NUMBER_OF_REVIEWS")), 'null'), '')::int as number_of_reviews,

    nullif(nullif(trim("REVIEW_SCORES_RATING"), 'null'), '')::numeric(5,2) as review_scores_rating,
    nullif(nullif(trim("REVIEW_SCORES_ACCURACY"), 'null'), '')::numeric(5,2) as review_scores_accuracy,
    nullif(nullif(trim("REVIEW_SCORES_CLEANLINESS"), 'null'), '')::numeric(5,2) as review_scores_cleanliness,
    nullif(nullif(trim("REVIEW_SCORES_CHECKIN"), 'null'), '')::numeric(5,2) as review_scores_checkin,
    nullif(nullif(trim("REVIEW_SCORES_COMMUNICATION"), 'null'), '')::numeric(5,2) as review_scores_communication,
    nullif(nullif(trim("REVIEW_SCORES_VALUE"), 'null'), '')::numeric(5,2) as review_scores_value,
    
    --Key/Text
    cast(trim("LISTING_ID") as text) as listing_id,
    cast(trim("SCRAPE_ID") as text) as scrape_id,
    cast(trim("HOST_ID") as text) as host_id,
    nullif(trim("HOST_NAME"),'') as host_name,
    case
    when trim("HOST_SINCE") ~ '^\d{4}-\d{2}-\d{2}$'
    then to_date(trim("HOST_SINCE"),'YYYY-MM-DD')
    else null
    end as host_since,
    nullif(lower(trim("HOST_NEIGHBOURHOOD")),'') as host_neighbourhood,
    nullif(lower(trim("LISTING_NEIGHBOURHOOD")),'') as listing_neighbourhood,
    nullif(trim("PROPERTY_TYPE"),'') as property_type,
    nullif(trim("ROOM_TYPE"),'') as room_type
    from del
),

filtered as (
    select *
    from deal
    {% if is_incremental() %}
    where scraped_date >
    (select coalesce(max(scraped_date), '1900-01-01'::timestamp) from {{ this }})
    or month_date >= (select coalesce(max(month_date), '1900-01-01'::date) from {{ this }})
    {% endif %}
),

-- Remove duplicate records in the same month
dedup as (
    select *
    from (
        select
        *,
        row_number() over (
            partition by listing_id, month_date
            order by scraped_date desc nulls last
        ) as rn
        from filtered
    ) z
    where rn = 1
)

select
{{ dbt_utils.generate_surrogate_key(['listing_id', 'month_date::text']) }} as listing_month_id,
listing_id, scrape_id, scraped_date, month_date,
host_id, host_name, host_since, host_is_superhost, host_neighbourhood,
listing_neighbourhood, property_type, room_type, accommodates,
price, has_availability, availability_30, number_of_reviews,
review_scores_rating, review_scores_accuracy, review_scores_cleanliness,
review_scores_checkin, review_scores_communication, review_scores_value
from dedup