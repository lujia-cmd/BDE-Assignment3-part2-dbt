{{ config(materialized='table') }}

with snapshot_property as (
    select
    property_type,
    room_type,
    accommodates,
    dbt_valid_from::date as valid_from,
    coalesce(dbt_valid_to, '9999-12-31')::date as valid_to
    from {{ ref('property_snapshot') }}
),

expanded as (
    select
    property_type,
    room_type,
    accommodates,
    date_trunc('month', gs)::date as year_month
    from snapshot_property,
    generate_series(valid_from, valid_to, interval '1 month') as gs
)

select
{{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text',"to_char(year_month, 'YYYY-MM')"]) }} as property_month_id,
{{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text']) }} as property_key,
* 
from expanded
order by property_type, room_type, accommodates, year_month