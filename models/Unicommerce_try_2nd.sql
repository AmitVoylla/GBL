{{ config(
    materialized='table',
    indexes=[
      {'columns': ['itemtypeskucode' ]}
    ]
)}}

SELECT * from public.voylla_in_unicommerce_v3_shelfwise_inventory
where  