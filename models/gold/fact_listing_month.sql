{{ config(materialized='table') }}

with base as (
    select
    listing_id,
    month_date,
    listing_neighbourhood,
    host_id,
    property_type,
    room_type,
    accommodates,
    price,
    availability_30,
    case when has_availability then 1 else 0 end as active_flag
    from {{ ref('airbnb_listing') }}
),

property as (
    select property_key, property_type, room_type, accommodates
    from {{ ref('dim_property') }}
),

suburb_map as (
    select suburb_key, suburb_name
    from {{ ref('dim_suburb') }}
),

host as (
    select host_month_id, host_id, month_date
    from {{ ref('dim_host_month') }}
)

select
b.listing_id,
b.month_date,
h.host_month_id,
p.property_key,
s.suburb_key,

--metrics
b.price,
case 
when b.active_flag=1 
then 30 - least(greatest(b.availability_30, 0), 30)
else 0
end as number_of_stays,
case when b.active_flag = 1
then (30 - least(greatest(b.availability_30, 0), 30)) * b.price
else 0
end::numeric(14,2) as estimated_revenue_active,

b.active_flag

from base b
left join host h
on h.host_id = b.host_id 
and h.month_date = b.month_date
left join property p
on p.property_type = b.property_type
and p.room_type = b.room_type
and p.accommodates = b.accommodates
left join suburb_map s
on s.suburb_name = b.listing_neighbourhood