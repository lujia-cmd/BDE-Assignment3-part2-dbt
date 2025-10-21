{{ config(materialized='table') }}

with base as (
    select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    month_date,
    scraped_date,
    row_number() over (
        partition by host_id, month_date
        order by scraped_date desc nulls last
    ) as rn
    from {{ ref('airbnb_listing') }}
    where host_id is not null
)

select
{{ dbt_utils.generate_surrogate_key(['host_id','month_date::text']) }} as host_month_id,
host_id,
host_name,
host_since,
host_is_superhost,
month_date,
scraped_date
from base
where rn = 1