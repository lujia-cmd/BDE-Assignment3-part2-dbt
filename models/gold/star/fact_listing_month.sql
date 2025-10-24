{{ config(
    materialized='incremental',
    unique_key=['listing_id', 'year_month'],
    incremental_strategy='delete+insert',
    on_schema_change='append_new_columns',
    pre_hook=[
       "{% if execute %}{% set rel = adapter.get_relation(database=this.database, schema=this.schema, identifier=this.identifier) %}{% if rel %}delete from {{ this }} where year_month = '{{ var(\"year_month\") }}'{% endif %}{% endif %}"
    ],
    post_hook=[
        "analyze {{ this }}",
        "create index if not exists {{ this.name }}_ym on {{ this }} (year_month)",
        "create index if not exists {{ this.name }}_md on {{ this }} (month_date)",
        "create index if not exists {{ this.name }}_lid on {{ this }} (listing_id)",
        "create index if not exists {{ this.name }}_hm  on {{ this }} (host_month_id)",
        "create index if not exists {{ this.name }}_pm  on {{ this }} (property_month_id)",
        "create index if not exists {{ this.name }}_sk  on {{ this }} (suburb_key)"
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
    (price)::numeric as price,
    availability_30,
    case when has_availability = 't' then 1 else 0 end as is_active,
    listing_neighbourhood
    from {{ ref('airbnb_listing') }}
    where year_month = '{{ var("year_month") }}'
),

host_m as (
    select host_month_id, host_id, month_from
    from {{ ref('dim_host_month') }}
),
prop_m as (
    select property_month_id, property_key, month_from
    from {{ ref('dim_property_month') }}
),
suburb_m as (
  select suburb_key, suburb_name
  from {{ ref('dim_suburb') }}
)

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

left join host_m h on b.host_id = h.host_id and b.month_date = h.month_from
left join prop_m p on b.property_key= p.property_key and b.month_date = p.month_from
left join suburb_m s on s.suburb_name= b.listing_neighbourhood