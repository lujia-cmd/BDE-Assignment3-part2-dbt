{{ config(
    materialized='table',
    post_hook=[
        "create index if not exists {{ this.name }}_rng on {{ this }} (property_key, month_from, month_to)",
        "analyze {{ this }}"
    ]
) }}

with snapshot_property as (
    select
    {{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text']) }} as property_key,
    property_type,
    room_type,
    accommodates,
    date_trunc('month', dbt_valid_from)::date as month_from,
    date_trunc('month', dbt_valid_to)::date as month_to
    from {{ ref('property_snapshot') }}
)
    
select
{{ dbt_utils.generate_surrogate_key(['property_key', "to_char(month_from,'YYYY-MM')"]) }} as property_month_id,
property_key,
property_type,
room_type,
accommodates,
month_from,
month_to
from snapshot_property



