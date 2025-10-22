{% snapshot property_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='property_key',
        strategy='timestamp',
        updated_at='scraped_date',
        invalidate_hard_deletes=false
    )
}}

with props as (
  select
    {{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text']) }} as property_key,
    property_type,
    room_type,
    accommodates,
    scraped_date
    from {{ ref('airbnb_listing') }}
    where property_type is not null and room_type is not null and accommodates is not null
)

select * from props
{% endsnapshot %}