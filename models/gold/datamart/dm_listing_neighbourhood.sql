{{ config(materialized='view') }}

with fact as (
    select
    f.listing_id,
    f.suburb_key,
    to_date(f.year_month || '-01','YYYY-MM-DD')::date as month_date,
    f.price,
    (f.is_active,
    f.number_of_stays,
    f.estimated_revenue_active,
    f.host_month_id
    from {{ ref('fact_listing_month') }} f
),

neigh as (
    select
    suburb_key,
    suburb_name as listing_neighbourhood
    from {{ ref('dim_suburb') }}
), 

host as (
    select
    host_month_id,
    host_id,
    host_is_superhost
    from {{ ref('dim_host_month') }}
),

reviews as (
    select
    listing_id,
    to_date(year_month || '-01','YYYY-MM-DD')::date as month_date,
    review_scores_rating
    from {{ ref('fact_review') }}
),

joined as (
    select
    coalesce(n.listing_neighbourhood, 'Unknown') as listing_neighbourhood,
    f.month_date,
    f.listing_id,
    f.price,
    coalesce(f.is_active, 0) as is_active,
    f.number_of_stays,
    f.estimated_revenue_active,
    h.host_id,
    h.host_is_superhost,
    r.review_scores_rating
    from fact f
    left join neigh n on f.suburb_key = n.suburb_key
    left join host h on f.host_month_id = h.host_month_id
    left join reviews r on r.listing_id = f.listing_id 
    and r.month_date = f.month_date
),

aggregator as (
    select
    listing_neighbourhood,
    month_date,
    count(*) as total_listings,
    sum(coalesce(is_active,0)) as active_listings,
    (count(*) - sum(coalesce(is_active,0))) as inactive_listings,

    --  Minimum, maximum, median and average price for active listings
    min(case when is_active=1 then price end) as min_price_active,
    max(case when is_active=1 then price end) as max_price_active,
    avg(case when is_active=1 then price end) as avg_price_active,
    percentile_cont(0.5) within group (order by case when is_active=1 then price end) as median_price_active,
    
    -- Number of distinct hosts
    count(distinct case when is_active = 1 then host_id end) as distinct_hosts,

    -- Superhost rate
    100.0 * count (distinct case when is_active=1 and host_is_superhost then host_id end) 
    / nullif(count(distinct case when is_active=1 then host_id end),0) as superhost_rate,

    --  Average of review_scores_rating for active listings
    avg(case when is_active=1 then review_scores_rating end) as avg_review_scores_rating_active,

    -- Total number of stays
    sum(number_of_stays) as total_number_of_stays,

    -- Average Estimated revenue per active listings 
    sum( case when is_active = 1 then estimated_revenue_active end)
    / nullif(sum(case when is_active = 1 then 1 else 0 end), 0) as avg_estimated_revenue_per_active
    
    from joined
    group by listing_neighbourhood, month_date
)

select
listing_neighbourhood,
month_date,
min_price_active,
max_price_active,
median_price_active,
avg_price_active,
distinct_hosts,
superhost_rate,
avg_review_scores_rating_active,
total_listings,
active_listings,
inactive_listings,


100.0 * active_listings / nullif(total_listings,0) as active_listing_rate,

-- Percentage change for active listings 
100.0 * (active_listings - lag(active_listings) over (partition by listing_neighbourhood order by month_date))
/ nullif(lag(active_listings) over (partition by listing_neighbourhood order by month_date),0) as per_change_active,

-- Percentage change for inactive listings 
100.0 * ((total_listings - active_listings) - lag(total_listings - active_listings) over (partition by listing_neighbourhood order by month_date))
/ nullif(lag(total_listings - active_listings) over (partition by listing_neighbourhood order by month_date),0) as per_change_inactive,

total_number_of_stays,
avg_estimated_revenue_per_active
from aggregator
order by listing_neighbourhood, month_date