{% snapshot host_snapshot %}
{{
    config(
        target_schema=target.schema, 
        unique_key='host_id',
        strategy='timestamp',
        updated_at='scraped_date::timestamp',
        post_hook=[
            "create index if not exists {{ this.name }}_uk on {{ this }} (host_id)",
            "analyze {{ this }}"
        ]
    )
}}
with latest as (
    select
    host_id,
    max(scraped_date::timestamp) as scraped_date
    from {{ ref('airbnb_listing') }}
    where host_id is not null
    group by host_id
)

select
l.host_id, l.host_name, l.host_since, l.host_is_superhost, latest.scraped_date
(scraped_date::timestamp) as scraped_date
from {{ ref('airbnb_listing') }} l
join latest using (host_id, scraped_date)
{% endsnapshot %}





