{{ config(
    materialized='incremental',
    unique_key='property_month_id',
    incremental_strategy='delete+insert',
    on_schema_change = 'append_new_columns',
    post_hook=[
        "analyze {{ this }}",
        "create index if not exists {{ this.name }}_pm on {{ this }} (property_key, month_from)"
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
    property_key,
    property_type,
    room_type,
    accommodates,
    dbt_valid_from,
    dbt_valid_to
    from {{ ref('property_snapshot') }}
),

valid_in_month as (
    select 
    s.property_key,
    s.property_type,
    s.room_type,
    s.accommodates,
    p.m_start as month_from
    from scd s
    join params p
    on s.dbt_valid_from < p.m_next
    and coalesce(s.dbt_valid_to, p.m_next) >= p.m_start
)


select
{{ dbt_utils.generate_surrogate_key(['property_key','month_from::text']) }} as property_month_id,
property_key,
month_from,
property_type,
room_type,
accommodates
from valid_in_month


