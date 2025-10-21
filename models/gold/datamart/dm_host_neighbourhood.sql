{{ config(materialized='view') }}

with base as (
    select
    f.month_date,
    h.host_id,
    s.lga_name as host_neighbourhood_lga,
    f.estimated_revenue_active
    from {{ ref('fact_listing_month') }} f
    join {{ ref('dim_suburb') }} s using (suburb_key)
    join {{ ref('dim_host_month') }} h using (host_month_id)
),

aggregator as (
    select
    host_neighbourhood_lga,
    month_date,
    count(distinct host_id) as distinct_hosts,
    sum(estimated_revenue_active) as total_estimated_revenue,
    sum(estimated_revenue_active) / nullif(count(distinct host_id), 0) as estimated_revenue_per_host
    from base
    group by 1, 2
)

select *
from aggregator
order by host_neighbourhood_lga, month_date