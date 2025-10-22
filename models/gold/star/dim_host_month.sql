{{ config(materialized='table') }}

with snapshot_host as (
    select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    dbt_valid_from
    from {{ ref('host_snapshot') }}
),

host_month as (
    select
    {{ dbt_utils.generate_surrogate_key(['host_id',"to_char(dbt_valid_from, 'YYYY-MM')"]) }} as host_month_id,
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    to_date(to_char(dbt_valid_from, 'YYYY-MM') || '-01', 'YYYY-MM-DD')::date as year_month
    from snapshot_host
)

select * from host_month