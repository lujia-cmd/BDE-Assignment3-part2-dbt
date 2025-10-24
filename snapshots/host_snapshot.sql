{% snapshot host_snapshot %}
{{
    config(
        target_schema=target.schema, 
        unique_key='host_id',
        strategy='timestamp',
        updated_at='scraped_date::timestamp',
        post_hook=[
            "create index if not exists {{ this.name }}_uk on {{ this }} (host_id)",
            "create index if not exists {{ this.name }}_vfrom on {{ this }} (dbt_valid_from)",
            "create index if not exists {{ this.name }}_uk_vf on {{ this }} (host_id, dbt_valid_from)",
            "analyze {{ this }}"
        ]
    )
}}

select
host_id, host_name, host_since, host_is_superhost,
scraped_date::timestamp as scraped_date
from {{ ref('airbnb_listing') }}
where host_id is not null
{% endsnapshot %}

