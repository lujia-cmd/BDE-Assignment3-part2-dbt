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
    date_trunc('month', dbt_valid_to)::date as month_to
    from {{ ref('host_snapshot') }}
    where host_id is not null
    and dbt_valid_from is not null
)

select
{{ dbt_utils.generate_surrogate_key(['host_id',"to_char(month_from,'YYYY-MM')"]) }} as host_month_id,
host_id,
host_name,
host_since,
host_is_superhost,
month_from, 
month_to
from snapshot_host