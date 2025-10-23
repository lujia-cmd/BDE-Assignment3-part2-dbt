{{ config(materialized='table', post_hook=["analyze {{ this }}"]) }}

with snapshot_host as (
    select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    dbt_valid_from::date as valid_from,
    coalesce(dbt_valid_to, '9999-12-31')::date as valid_to
    from {{ ref('host_snapshot') }}
),

expanded as (
    select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    date_trunc('month', gs)::date as year_month
    from snapshot_host,
    generate_series(valid_from, valid_to, interval '1 month') as gs
)

select
{{ dbt_utils.generate_surrogate_key(['host_id',"to_char(year_month,'YYYY-MM')"]) }} as host_month_id,
*
from expanded
order by host_id, year_month