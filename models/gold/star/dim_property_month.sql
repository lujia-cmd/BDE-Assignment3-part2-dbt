{{ config(
    materialized='table',
    post_hook=[
      "create index if not exists {{ this.name }}_range on {{ this }} (property_key, valid_from, valid_to)",
      "create index if not exists {{ this.name }}_attrs on {{ this }} (property_type, room_type, accommodates, valid_from, valid_to)",
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

select
{{ dbt_utils.generate_surrogate_key(['property_key', "to_char(valid_from, 'YYYY-MM-DD')"]) }} as property_month_id,
property_key,
property_type,
room_type,
accommodates,
valid_from,
valid_to

from snapshot_property

