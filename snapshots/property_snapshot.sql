{% snapshot property_snapshot %}

{{
    config(
        target_schema=target.schema,
        unique_key='property_key',
        strategy='timestamp',
        updated_at='scraped_month',
        post_hook=[
            "create index if not exists {{ this.name }}_uk on {{ this }} (host_id)",
            "analyze {{ this }}"
        ]
    )
}}

with staged as (
    select
    {{ dbt_utils.generate_surrogate_key(['property_type','room_type','accommodates::text']) }} as property_key,
    property_type,
    room_type,
    accommodates,
    (scraped_date::timestamp) as scraped_ts,
    date_trunc('month', (scraped_date::timestamp)) as scraped_month
    from {{ ref('airbnb_listing') }}
    where property_type is not null
    and room_type is not null
    and accommodates is not null
),

dedup_month as (
    select *
    from (
        select
        property_key, property_type, room_type, accommodates, scraped_month,
        row_number() over (
            partition by property_key, scraped_month
            order by scraped_ts desc nulls last
        ) as rn
    from staged
    ) t
    where rn = 1
)

select
property_key, property_type, room_type, accommodates, scraped_month
from dedup_month

{% endsnapshot %}

