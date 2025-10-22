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
    regexp_replace("HOST_SINCE"::text, E'[\\u00A0\\u2000-\\u200B\\s]', '', 'g') as host_since_raw,
    
    "ACCOMMODATES", "AVAILABILITY_30", "NUMBER_OF_REVIEWS",
    "REVIEW_SCORES_RATING", "REVIEW_SCORES_ACCURACY", "REVIEW_SCORES_CLEANLINESS",
    "REVIEW_SCORES_CHECKIN", "REVIEW_SCORES_COMMUNICATION", "REVIEW_SCORES_VALUE",
    "LISTING_ID", "SCRAPE_ID", "HOST_ID", "HOST_NAME", "HOST_SINCE",
    "HOST_NEIGHBOURHOOD", "LISTING_NEIGHBOURHOOD", "PROPERTY_TYPE", "ROOM_TYPE"
    from {{ source('bronze','airbnb_052020') }}
),

deal as (
    select
    -- Timestamp: YYYY-MM-DD
    to_date(scraped_date_raw, 'YYYY-MM-DD')::timestamp as scraped_date,
    to_char(date_trunc('month', to_date(scraped_date_raw, 'YYYY-MM-DD')), 'YYYY-MM') as year_month,

    --Price Cleaning
    case
    when replace(price_raw, ',', '') ~ '^\d+(\.\d+)?$'
    then replace(price_raw, ',', '')::numeric(12,2)
    else null
    end as price,

    --Bool
    case
    when lower(has_availability_raw) in ('t','true','1','y') then true
    else false
    end as has_availability,

    case
    when lower(host_is_superhost_raw) in ('t','true','1','y') then true
    else false
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
    when host_since_raw ~ '^\d{1,2}/\d{1,2}/\d{4}$'
    then to_char(to_date(host_since_raw, 'DD/MM/YYYY'), 'YYYY-MM-DD')
    when host_since_raw ~ '^\d{4}-\d{1,2}-\d{1,2}$'
    then to_char(to_date(host_since_raw, 'YYYY-MM-DD'), 'YYYY-MM-DD')
    when host_since_raw ~ '^\d{1,2}-\d{1,2}-\d{4}$'
    then to_char(to_date(host_since_raw, 'DD-MM-YYYY'), 'YYYY-MM-DD')
    when host_since_raw ~ '^\d{4}-\d{1,2}-\d{1,2}$'
    then to_char(to_date(host_since_raw, 'YYYY-MM-DD'), 'YYYY-MM-DD')
    else null
    end as host_since,
    nullif(lower(trim("HOST_NEIGHBOURHOOD")),'') as host_neighbourhood,
    nullif(lower(trim("LISTING_NEIGHBOURHOOD")),'') as listing_neighbourhood,
    nullif(trim("PROPERTY_TYPE"),'') as property_type,
    nullif(trim("ROOM_TYPE"),'') as room_type
    from del
),

{% if is_incremental() %}
filtered as (
    select *
    from deal
    where (year_month, coalesce(scraped_date,'1900-01-01'::timestamp)) > (select coalesce(max(year_month),'1900-01'),
    coalesce(max(scraped_date),'1900-01-01'::timestamp)
    from {{ this }})
),

base as (select * from filtered)
{% else %}
base as (select * from deal)
{% endif %},


-- Remove duplicate records in the same month
dedup as (
    select *
    from (
        select
        *,
        row_number() over (
            partition by listing_id, year_month
            order by scraped_date desc nulls last
        ) as rn
        from base
    ) t
    where rn = 1
)

select
{{ dbt_utils.generate_surrogate_key(['listing_id', 'year_month']) }} as listing_month_id,
listing_id, scrape_id, scraped_date, year_month,
host_id, host_name, host_since, host_is_superhost, host_neighbourhood,
listing_neighbourhood, property_type, room_type, accommodates,
price, has_availability, availability_30, number_of_reviews,
review_scores_rating, review_scores_accuracy, review_scores_cleanliness,
review_scores_checkin, review_scores_communication, review_scores_value
from dedup