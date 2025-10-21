{{ config(materialized='view') }}

with fact as (
    select
    f.listing_id,
    f.month_date,
    s.suburb_name as listing_neighbourhood,
    f.host_month_id,
    f.price,
    f.number_of_stays,
    f.estimated_revenue_active,
    f.active_flag as is_active
    from {{ ref('fact_listing_month') }} f
    join {{ ref('dim_suburb') }} s using (suburb_key)
),

aggregator as (
    select
    listing_neighbourhood,
    f.month_date,
    count(*) as total_listings,
    sum(is_active) as active_listings,

    --  Minimum, maximum, median and average price for active listings
    min(case when is_active=1 then price end) as min_price_active,
    max(case when is_active=1 then price end) as max_price_active,
    avg(case when is_active=1 then price end) as avg_price_active,
    percentile_cont(0.5) within group (order by case when is_active=1 then price end) as median_price_active,
    
    -- Number of distinct hosts
    count(distinct case when is_active=1 then h.host_id end) as distinct_hosts,

    -- Superhost rate
    100.0 * count (distinct case when is_active=1 and h.host_is_superhost then h.host_id end) 
    / nullif(count(distinct case when is_active=1 then h.host_id end),0) as superhost_rate,

    --  Average of review_scores_rating for active listings
    avg(case when is_active=1 then r.review_scores_rating end) as avg_review_scores_rating_active,

    -- Total number of stays
    sum(number_of_stays) as total_number_of_stays,

    -- Average Estimated revenue per active listings 
    avg(case when is_active=1 then estimated_revenue_active end) as avg_estimated_revenue_per_active
    
    from fact f
    left join {{ ref('dim_host_month') }} h using (host_month_id)
    left join {{ ref('fact_review') }} r 
    on r.listing_id = f.listing_id
    and r.month_date = f.month_date
    group by listing_neighbourhood, f.month_date
),

final as (
    select *,
    100.0 * active_listings / nullif(total_listings,0) as active_listing_rate,

    -- Percentage change for active listings 
    100.0 * (active_listings - lag(active_listings) over (partition by listing_neighbourhood order by month_date))
    / nullif(lag(active_listings) over (partition by listing_neighbourhood order by month_date),0) as per_change_active,

    -- Percentage change for inactive listings 
    100.0 * ((total_listings - active_listings) - lag(total_listings - active_listings) over (partition by listing_neighbourhood order by month_date))
    / nullif(lag(total_listings - active_listings) over (partition by listing_neighbourhood order by month_date),0) as per_change_inactive
  from aggregator
)

select *
from final
order by listing_neighbourhood, month_date