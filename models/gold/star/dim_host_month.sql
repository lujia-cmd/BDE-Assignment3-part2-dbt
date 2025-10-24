{{ config(materialized='table',
    post_hook=[
      "create index if not exists {{ this.name }}_range on {{ this }} (host_id, month_from, month_to)",
      "analyze {{ this }}"
    ]
) }}
    
with snapshot_host as (
    select
    host_id,
    host_name,
    host_since,
    host_is_superhost,
    date_trunc('month', dbt_valid_from)::date as month_from,
    date_trunc('month', coalesce(dbt_valid_to, '9999-12-31'))::date as month_to
    from {{ ref('host_snapshot') }}
)

select
{{ dbt_utils.generate_surrogate_key(['host_id',"month_from')"]) }} as host_month_id,
host_id,
host_name,
host_since,
host_is_superhost,
month_from, 
month_to
from snapshot_host
