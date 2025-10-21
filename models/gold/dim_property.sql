{{ config(materialized='table') }}

select
property_key,
property_type,
room_type,
accommodates
from {{ ref('dimension_property') }}