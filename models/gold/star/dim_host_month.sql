{{ config(materialized='incremental',
    unique_key='host_month_id',
    incremental_strategy='delete+insert',
    post_hook=[
      "create index if not exists {{ this.name }}_range on {{ this }} (host_id, month_from)"
    ]
) }}

{% if not var('year_month', none) %}
{{ exceptions.raise("Missing var: year_month (e.g. --vars 'year_month: \"2020-05\"')") }}
{% endif %}

with params as (
    select
    to_date('{{ var("year_month") }}-01','YYYY-MM-DD')::date as m_start,
    (to_date('{{ var("year_month") }}-01','YYYY-MM-DD') + interval '1 month')::date as m_next
),
scd as (
    select 
    host_id, 
    (host_is_superhost in ('t', 'true', 'True')) as host_is_superhost,
    dbt_valid_from, dbt_valid_to
    from {{ ref('host_snapshot') }}
),
valid_in_month as (
    select s.host_id, s.host_is_superhost, p.m_start as month_from
    from scd s
    join params p
    on s.dbt_valid_from < p.m_next
    and coalesce(s.dbt_valid_to, p.m_next) >= p.m_start
)

select
{{ dbt_utils.generate_surrogate_key(['host_id','month_from::text']) }} as host_month_id,
host_id,
month_from,
host_is_superhost
from valid_in_month