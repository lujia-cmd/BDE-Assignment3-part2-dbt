{{ config(materialized='table',
    post_hook=[
      "create index if not exists {{ this.name }}_range on {{ this }} (host_id, valid_from, valid_to)",
      "analyze {{ this }}"
    ]
) }}
    
with snapshot_host as (
    select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    dbt_valid_from::date as valid_from,
    coalesce(dbt_valid_to, '9999-12-31')::date as valid_to
    from {{ ref('host_snapshot') }}
),

select
{{ dbt_utils.generate_surrogate_key(['host_id',"to_char(valid_from,'YYYY-MM')"]) }} as host_month_id,
host_id,
host_name,
host_since,
host_is_superhost,
valid_from, 
valid_to

from snapshot_host
