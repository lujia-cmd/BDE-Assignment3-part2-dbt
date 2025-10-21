{{ config(materialized='table') }}

with lga_suburb as (
    select
    lower(trim("SUBURB_NAME")) as suburb_name_norm,
    lower(trim("LGA_NAME")) as lga_name_norm
    from {{ source('bronze','lga_suburb') }}
    where "SUBURB_NAME" is not null and trim("SUBURB_NAME") <> ''
),

lga_code as (
    select
    trim("LGA_CODE") as lga_code,
    lower(trim("LGA_NAME")) as lga_name_norm
    from {{ source('bronze','lga_code') }}
    where "LGA_CODE" is not null and trim("LGA_CODE") <> ''
),

joined as (
    select
    s.suburb_name_norm,
    c.lga_code,
    c.lga_name_norm
    from lga_suburb s
    left join lga_code c
    on s.lga_name_norm = c.lga_name_norm
)

select
{{ dbt_utils.generate_surrogate_key(['suburb_name_norm','lga_code']) }} as suburb_key,
suburb_name_norm as suburb_name,
lga_code,
lga_name_norm as lga_name
from joined
where lga_code is not null