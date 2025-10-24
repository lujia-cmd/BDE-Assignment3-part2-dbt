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
    dbt_valid_from::date as valid_from,
    coalesce(dbt_valid_to, '9999-12-31')::date as valid_to
    from {{ ref('property_snapshot') }}
)

mon as (
    select
    property_key, property_type, room_type, accommodates,
    date_trunc('month', valid_from)::date as month_from,
    date_trunc('month', valid_to)::date as month_to,
    row_number() over (
        partition by property_key, date_trunc('month', valid_from)
        order by valid_from desc
    ) as rn
    from s
),

del as (select * from m where rn = 1)
    
select
{{ dbt_utils.generate_surrogate_key(['property_key', "to_char(month_from, 'YYYY-MM')"]) }} as property_month_id,
property_key,
property_type,
room_type,
accommodates,
month_from,
month_to

from del
