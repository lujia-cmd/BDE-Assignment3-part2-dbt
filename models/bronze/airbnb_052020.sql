{{ config(materialized='view') }}
select * from {{ source('bronze', 'airbnb_052020') }}