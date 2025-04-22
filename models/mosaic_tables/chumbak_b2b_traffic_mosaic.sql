{{ config(
    materialized='table',
    indexes=[
        {'columns': ['"ASIN"', '"Brand"']},
    ]
) }}


SELECT 
  avfd.asin AS "ASIN",
    ffabm.product_name AS "Product Title",
  CASE 
    WHEN ffabm.product_name ILIKE '%TEAL BY%' THEN 'TEAL BY CHUMBAK'
    ELSE 'Chumbak'
  END AS "Brand",
  avfd.glanceviews AS "Glance Views",
  avfd.startdate AS "Date"
FROM dbt_dsarkar.az_vc_data_final avfd
LEFT JOIN dbt_dsarkar."FlatFile_Asin_Brand_Mapping" ffabm 
  ON avfd.asin = ffabm.asin
WHERE avfd.startdate >= date_trunc('week', CURRENT_DATE) - INTERVAL '7 days'
  AND avfd.startdate < date_trunc('week', CURRENT_DATE)
AND avfd.brand ='Chumbak'
AND avfd.glanceviews IS NOT NULL
ORDER BY avfd.startdate

