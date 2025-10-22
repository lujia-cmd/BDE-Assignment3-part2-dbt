{% snapshot host_snapshot %}

{{
    config(
        target_schema='snapshots', 
        unique_key='host_id',
        strategy='timestamp',
        updated_at='scraped_date',
        invalidate_hard_deletes=false 
    )
}}

select
host_id,
host_name,
host_since,
host_is_superhost,
scraped_date
from {{ ref('airbnb_listing') }}
where host_id is not null

{% endsnapshot %}