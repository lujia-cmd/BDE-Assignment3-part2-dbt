{{ config(materialized='view') }}

with fact as (
    select
    f.listing_id,
    to_date(f.year_month || '-01','YYYY-MM-DD')::date as month_date,
    f.host_month_id,
    p.property_type,
    p.room_type,
    p.accommodates,
    f.price,
    f.number_of_stays,
    f.estimated_revenue_active,
    f.is_active
    from {{ ref('fact_listing_month') }} f
    join {{ ref('dim_property_month') }} p 
    on p.property_month_id = f.property_month_id
),

joined as (
    select
    property_type, 
    room_type, 
    accommodates,
    f.month_date,
    f.price,
    f.number_of_stays,
    f.estimated_revenue_active,
    coalesce(f.is_active, 0) as is_active,
    h.host_id,
    h.host_is_superhost,
    r.review_scores_rating
    from fact f
    left join {{ ref('dim_host_month') }} h
    on h.host_month_id = f.host_month_id
    left join {{ ref('fact_review') }} r
    on r.listing_id = f.listing_id
    and to_date(r.year_month || '-01','YYYY-MM-DD')::date = f.month_date
),

aggregator as (
    select
    property_type,
    room_type,
    accommodates,
    month_date,
    count(*) as total_listings,
    sum(coalesce(is_active,0)) as active_listings,
    (count(*) - sum(coalesce(is_active,0))) as inactive_listings,

    --  Minimum, maximum, median and average price for active listings
    min(case when is_active=1 then price end) as min_price_active,
    max(case when is_active=1 then price end) as max_price_active,
    avg(case when is_active=1 then price end) as avg_price_active,
    percentile_cont(0.5) within group (order by price::numeric) filter (where is_active=1 and price is not null) as median_price_active,
    
    -- Number of distinct hosts
    count(distinct case when is_active=1 then host_id end) as distinct_hosts,

    -- Superhost rate
    100.0 * coalesce(count (distinct case when is_active=1 and host_is_superhost then host_id end),0)
    / nullif(count(distinct case when is_active=1 then host_id end),0) as superhost_rate,

    --  Average of review_scores_rating for active listings
    avg(case when is_active=1 then review_scores_rating end) as avg_review_scores_rating_active,

    -- Total number of stays
    sum(number_of_stays) as total_number_of_stays,

    -- Average Estimated revenue per active listings 
    coalesce(sum(case when is_active=1 then estimated_revenue_active end)
    / nullif(sum(case when is_active=1 then 1 else 0 end),0),0) as avg_estimated_revenue_per_active
    from joined
    group by property_type, room_type, accommodates, month_date
)

select *,
100.0 * active_listings / nullif(total_listings, 0) as active_listing_rate,

-- Percentage change for active listings 
coalesce(100.0 * (active_listings - lag(active_listings) over (partition by property_type, room_type, accommodates order by month_date))
/ nullif(lag(active_listings) over (partition by property_type, room_type, accommodates order by month_date), 0), 0) as per_change_active,

-- Percentage change for inactive listings 
coalesce(100.0 * ((total_listings - active_listings) - lag(total_listings - active_listings) over (partition by property_type, room_type, accommodates order by month_date))
/ nullif(lag(total_listings - active_listings) over (partition by property_type, room_type, accommodates order by month_date), 0), 0) as per_change_inactive
from aggregator

order by property_type, room_type, accommodates, month_date
