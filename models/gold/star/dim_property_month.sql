{{ config(materialized='table') }}

with snapshot_property as (
    select
    property_type,
    room_type,
    accommodates,
    dbt_valid_from
    from {{ ref('property_snapshot') }}
),

property_month as (
    select
    {{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text',"to_char(dbt_valid_from, 'YYYY-MM')"]) }} as property_month_id,
    {{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text']) }} as property_key,
    property_type,
    room_type,
    accommodates,
    to_date(to_char(dbt_valid_from, 'YYYY-MM') || '-01', 'YYYY-MM-DD')::date as year_month
    from snapshot_property
)

select * from property_month