{{ config(materialized='view') }}

with host_latest as (
    select 
    host_id,
    to_date(year_month || '-01','YYYY-MM-DD')::date as month_date, 
    host_neighbourhood
    from (
        select
        host_id,
        year_month,
        host_neighbourhood,
        scraped_date,
        row_number() over (
            partition by host_id, year_month
            order by scraped_date desc nulls last
        ) as rn
        from {{ ref('airbnb_listing') }}
        where host_id is not null
    ) t
    where rn = 1
),

map as (
    select
    suburb_name,
    lga_name
    from {{ ref('dim_suburb') }}
),

base as (
    select
    to_date(f.year_month || '-01','YYYY-MM-DD')::date as month_date,
    dhm.host_id,
    m.lga_name as host_neighbourhood_lga,
    f.estimated_revenue_active
    from {{ ref('fact_listing_month') }} f
    left join {{ ref('dim_host_month') }} dhm
    on dhm.host_month_id = f.host_month_id
    left join host_latest h
    on h.host_id = dhm.host_id
    and h.month_date = to_date(f.year_month || '-01','YYYY-MM-DD')::date
    left join map m
    on h.host_neighbourhood = m.suburb_name
)

select
host_neighbourhood_lga,
month_date,
count(distinct host_id) as distinct_hosts,
sum(estimated_revenue_active) as estimated_revenue,
round(sum(estimated_revenue_active) / nullif(count(distinct host_id), 0), 2) as estimated_revenue_per_host
from base
where host_neighbourhood_lga is not null
group by host_neighbourhood_lga, month_date
order by host_neighbourhood_lga, month_date