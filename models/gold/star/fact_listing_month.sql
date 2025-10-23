{{ config(
    materialized='incremental',
    unique_key='listing_id || year_month',
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
    post_hook=[
      "analyze {{ this }}",
      "create index if not exists {{ this.name }}_ym on {{ this }} (year_month)",
      "create index if not exists {{ this.name }}_lid on {{ this }} (listing_id)",
    ]
) }}

with base as (
    select
    listing_id,
    year_month,
    listing_neighbourhood,
    host_id,
    property_type,
    room_type,
    accommodates,
    price,
    availability_30,
    case when has_availability then 1 else 0 end as is_active
    from {{ ref('airbnb_listing') }}
    {% if is_incremental() %}
    where year_month = '{{ var("year_month") }}'
    {% endif %}
),

-- Host dimension: same as (host_id, year_month) only one entry left
host_dedup as (
    select
    host_month_id, host_id, year_month,
    row_number() over (
    partition by host_id, year_month
    order by host_month_id desc
    ) as rn
    from {{ ref('dim_host_month') }}
),       
host_to1 as (
    select host_month_id, host_id, year_month
    from host_dedup
    where rn = 1
),

-- Listing Dimension (Monthly): same as (ptype, rtype, accom, year_month) Leave one entry only
prop_dedup as (
    select
    property_month_id, property_key,
    property_type, room_type, accommodates, year_month,
    row_number() over (
        partition by property_type, room_type, accommodates, year_month
        order by property_month_id desc
    ) as rn
    from {{ ref('dim_property_month') }}
),
prop_to1 as (
    select property_month_id, property_key, property_type, room_type, accommodates, year_month
    from prop_dedup
    where rn = 1
),

-- Suburb to LGA: only one mapping is kept for the same suburb
suburb_dedup as (
    select
    suburb_key, suburb_name,
    row_number() over (
    partition by lower(trim(suburb_name))
    order by suburb_key
    ) as rn
    from {{ ref('dim_suburb') }}
),
suburb_to1 as (
    select suburb_key, suburb_name
    from suburb_dedup
    where rn = 1
),

joined as (
    select
    b.listing_id,
    b.year_month,
    h.host_month_id,
    p.property_month_id,
    p.property_key,
    s.suburb_key,
    b.price,
    b.availability_30,
    b.is_active
    from base b
    left join host_to1 h
    on b.host_id = h.host_id
    and to_date(b.year_month || '-01','YYYY-MM-DD') = h.year_month
    left join prop_to1 p
    on p.property_type = b.property_type
    and p.room_type= b.room_type
    and p.accommodates = b.accommodates
    and to_date(b.year_month || '-01','YYYY-MM-DD') = p.year_month
    left join suburb_to1 s
    on s.suburb_name = b.listing_neighbourhood
),

final as (
    select
    listing_id,
    year_month,
    host_month_id,
    property_month_id,
    property_key,
    suburb_key,
    price,
    case
    when is_active = 1
    then 30 - least(greatest(coalesce(availability_30,0), 0), 30)
    else 0
    end as number_of_stays,
    case
    when is_active = 1
    then (30 - least(greatest(coalesce(availability_30,0), 0), 30)) * price
    else 0
    end::numeric(14,2) as estimated_revenue_active,
    is_active
    from joined
)


select * from final
