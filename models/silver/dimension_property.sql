{{ config(materialized='table') }}

with distinct_props as (
    select distinct
    nullif(property_type, '') as property_type,
    nullif(room_type, '') as room_type,
    accommodates
    from {{ ref('airbnb_listing') }}
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