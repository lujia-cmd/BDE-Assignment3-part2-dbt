{{ config(
    materialized='incremental',
    unique_key='listing_id || year_month',
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns',
    post_hook=[
      "analyze {{ this }}",
      "create index if not exists {{ this.name }}_ym on {{ this }} (year_month)",
      "create index if not exists {{ this.name }}_lid on {{ this }} (listing_id)",
      "create index if not exists {{ this.name }}_md on {{ this }} (month_date)"
    ]
) }}

with base as (
    select
    listing_id,
    year_month,
    to_date(year_month || '-01','YYYY-MM-DD')::date as month_date,
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

-- Suburb to LGA: only one mapping is kept for the same suburb
suburb_to1 as (
    select suburb_key, suburb_name
    from (
        select *, row_number() over (
            partition by lower(trim(suburb_name))
            order by suburb_key
        ) as rn
        from {{ ref('dim_suburb') }}
    ) t where rn = 1
),

joined as (
    select
    b.listing_id,
    b.year_month,
    b.month_date,
    h.host_month_id,
    p.property_month_id,
    p.property_key,
    s.suburb_key,
    b.price,
    b.availability_30,
    b.is_active
    from base b

    -- SCD2: Interval connection host dimension
    left join {{ ref('dim_host_month') }} h
    on h.host_id = b.host_id
    and b.month_date >= h.year_month
    and b.month_date <  h.valid_to

    -- SCD2: Interval concatenation property dimension (match by property + interval)
    left join {{ ref('dim_property_month') }} p
    on p.property_type = b.property_type
    and p.room_type= b.room_type
    and p.accommodates = b.accommodates
    and b.month_date >= p.valid_from
    and b.month_date <  p.valid_to

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
