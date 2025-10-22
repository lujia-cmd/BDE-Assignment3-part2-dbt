{{ config(materialized='table') }}

with distinct_props as (
    select distinct
    property_type,
    room_type,
    accommodates
    from {{ ref('airbnb_listing') }}
    where accommodates is not null and accommodates >= 1
)

select
{{ dbt_utils.generate_surrogate_key([
    'property_type',
    'room_type',
    'accommodates'
]) }} as property_key,
property_type,
room_type,
accommodates
from distinct_props