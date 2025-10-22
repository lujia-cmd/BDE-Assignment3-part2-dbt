{{ config(materialized='table') }}

select
trim("LGA_CODE_2016")::text as lga_code,

nullif(trim("Median_age_persons"), '')::int as median_age_persons,
nullif(trim("Median_mortgage_repay_monthly"), '')::int as median_mortgage_repay_monthly,
nullif(trim("Median_tot_prsnl_inc_weekly"), '')::int as median_tot_prsnl_inc_weekly, 
nullif(trim("Median_rent_weekly"), '')::int as median_rent_weekly, 
nullif(trim("Median_tot_fam_inc_weekly"), '')::int as median_tot_fam_inc_weekly,
nullif(trim("Average_num_psns_per_bedroom"), '')::numeric(5,2) as average_num_psns_per_bedroom, 
nullif(trim("Median_tot_hhd_inc_weekly"), '')::int as median_tot_hhd_inc_weekly, 
nullif(trim("Average_household_size"), '')::numeric(5,2) as average_household_size
    
from {{ source('bronze','census_g02') }}
where "LGA_CODE_2016" is not null