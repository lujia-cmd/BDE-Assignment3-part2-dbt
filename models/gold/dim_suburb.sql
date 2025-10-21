{{ config(materialized='table') }}

select
suburb_key,
suburb_name,
lga_code,
lga_name
from {{ ref('dimension_lgamap') }}