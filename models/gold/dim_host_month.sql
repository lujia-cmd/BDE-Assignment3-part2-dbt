{{ config(materialized='table') }}

select
host_month_id,
host_id,
month_date,
host_name,
host_since,
host_is_superhost
from {{ ref('dimension_host') }}