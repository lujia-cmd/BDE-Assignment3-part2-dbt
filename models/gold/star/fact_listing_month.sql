{{ config(
    materialized='incremental',
    unique_key=['listing_id', 'year_month'],
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns',
    post_hook=[
      "analyze {{ this }}",
      "create index if not exists {{ this.name }}_ym on {{ this }} (year_month)",
      "create index if not exists {{ this.name }}_lid on {{ this }} (listing_id)",
      "create index if not exists {{ this.name }}_md on {{ this }} (month_date)"
    ]
) }}

{% if not var('year_month', none) %}
{{ exceptions.raise("Missing var: year_month (e.g. --vars 'year_month: \"2020-05\"')") }}
{% endif %}

with base as (
    select
    listing_id,
    year_month,
    to_date(year_month || '-01','YYYY-MM-DD')::date as month_date,
    host_id,
    coalesce(nullif(trim(property_type),''), 'Unknown') as property_type,
    coalesce(nullif(trim(room_type),''), 'Unknown') as room_type,
    accommodates,
    {{ dbt_utils.generate_surrogate_key([
      "coalesce(nullif(trim(property_type),''), 'Unknown')", "coalesce(nullif(trim(room_type),''), 'Unknown')",
      "accommodates::text"]) }} as property_key,
    price,
    availability_30,
    case when has_availability then 1 else 0 end as is_active,
    listing_neighbourhood
    from {{ ref('airbnb_listing') }}
    where year_month = '{{ var("year_month") }}'
),

joined as (
    select
    b.listing_id,
    b.year_month,
    b.month_date,
    h.host_month_id,
    p.property_month_id,
    s.suburb_key,
    b.price,
    case when b.is_active = 1
    then 30 - least(greatest(coalesce(b.availability_30,0), 0), 30)
    else 0 end as number_of_stays,
    case when b.is_active = 1
    then (30 - least(greatest(coalesce(b.availability_30,0), 0), 30)) * b.price
    else 0 end::numeric(14,2) as estimated_revenue_active,
    b.is_active
    from base b

    left join {{ ref('dim_host_month') }} h
    on b.host_id = h.host_id
    and b.month_date >= h.month_from
    and (h.month_to is null or b.month_date < h.month_to)

    left join {{ ref('dim_property_month') }} p
    on b.property_key = p.property_key
    and b.month_date >= p.month_from
    and (p.month_to is null or b.month_date < p.month_to)

    left join {{ ref('dim_suburb') }} s
    on s.suburb_name = b.listing_neighbourhood
)

select
listing_id,
year_month,
month_date,
host_month_id,
property_month_id,
suburb_key,
price,
number_of_stays,
estimated_revenue_active,
is_active
from joined