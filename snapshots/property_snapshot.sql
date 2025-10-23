{% snapshot property_snapshot %}

{{
    config(
        target_schema=target.schema,
        unique_key='property_key',
        strategy='timestamp',
        updated_at='scraped_date',
        post_hook=[
            "create index if not exists {{ this.name }}_uk on {{ this }} (property_key)",
            "create index if not exists {{ this.name }}_vfrom on {{ this }} (dbt_valid_from)",
            "create index if not exists {{ this.name }}_uk_vf on {{ this }} (property_key, dbt_valid_from)",
            "analyze {{ this }}"
        ]
    )
}}

with base as (
    select
    {{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text']) }} as property_key,
    property_type,
    room_type,
    accommodates,
    scraped_date::timestamp as scraped_date,
    from {{ ref('airbnb_listing') }}
    where property_type is not null and room_type is not null and accommodates is not null
)

select * from base

{% endsnapshot %}