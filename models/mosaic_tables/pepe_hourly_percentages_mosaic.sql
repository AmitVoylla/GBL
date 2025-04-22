{{ config(
    materialized='table',
    indexes=[
        {'columns': ['category_final']}
    ]
) }}

SELECT
   CASE
       WHEN category = 'BASIS VEST' THEN 'VEST'
       WHEN category = 'BERMUDA' THEN 'BOXER'
       WHEN category = 'BLACK GOLD SLEEPWEAR SET' THEN 'SLEEPWEAR'
       WHEN category = 'BOXER' THEN 'BOXER'
       WHEN category = 'BRIEF' THEN 'BRIEF'
       WHEN category = 'CLASSIC SLEEPWEAR PYJAMA' THEN 'SLEEPWEAR'
       WHEN category = 'CLASSIC SLEEPWEAR SET' THEN 'SLEEPWEAR'
       WHEN category = 'DRESS' THEN 'SLEEPWEAR'
       WHEN category = 'GYM VEST' THEN 'GYM VEST'
       WHEN category = 'LONG DRESS' THEN 'SLEEPWEAR'
       WHEN category = 'ONLY PLAY SLEEPWEAR SET' THEN 'SLEEPWEAR'
       WHEN category = 'PYJAMA' THEN 'SLEEPWEAR'
       WHEN category = 'SATIN BOXER' THEN 'BOXER'
       WHEN category = 'SHORTS' THEN 'SHORTS'
       WHEN category = 'SLEEP WEAR SET' THEN 'SLEEPWEAR'
       WHEN category = 'Socks' THEN 'SOCKS'
       WHEN category = 'THERMAL BOTTOM' THEN 'THERMAL'
       WHEN category = 'THERMAL TOP' THEN 'THERMAL'
       WHEN category = 'THERMAL TOP AND BOTTOM' THEN 'THERMAL'
       WHEN category = 'TRACK PANT' THEN 'TRACK PANT'
       WHEN category = 'TRACKSUIT' THEN 'TRACKSUIT'
       WHEN category = 'TRUNK' THEN 'TRUNK'
       WHEN category = 'T-SHIRT' THEN 'T-SHIRT'
       WHEN category = 'Vest' THEN 'VEST'
       WHEN category = 'Women Active Pant' THEN 'Women Active Pant'
       WHEN category = 'Women Camisole' THEN 'Women Camisole'
       WHEN category = 'Women Hipster' THEN 'Women Hipster'
       WHEN category = 'Women Sleep Set' THEN 'WOMEN SMU'
       WHEN category = 'Women Tanktop' THEN 'WOMEN SMU'
       WHEN category = 'Women Trackpant' THEN 'WOMEN SMU'
       WHEN category = 'Women T-Shirt' THEN 'Women T-Shirt'
       ELSE 'Unknown'
   END AS category_final,
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 0 AND 2) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "00-03 AM %",
  
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 3 AND 5) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "03-06 AM %",
  
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 6 AND 8) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "06-09 AM %",
  
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 9 AND 11) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "09-12 AM %",
  
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 12 AND 14) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "12-03 PM %",
  
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 15 AND 17) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "03-06 PM %",
  
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 18 AND 20) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "06-09 PM %",
  
   COALESCE(
       ROUND(
           (SUM(CAST(sellingprice AS NUMERIC)) FILTER (WHERE EXTRACT(HOUR FROM CAST(created AS TIMESTAMP)) BETWEEN 21 AND 23) * 100)
           / NULLIF(SUM(CAST(sellingprice AS NUMERIC)), 0), 1
       ), 0
   ) AS "09-12 PM %"
  
FROM dbt_dsarkar.uniware_sales_all_data usd
   LEFT JOIN dbt_dsarkar.channel_mapping_sheet cm
       ON usd.channelname = cm.channelname
   WHERE CAST(usd.created AS DATE) BETWEEN DATE_TRUNC('week', NOW()) - INTERVAL '7 days' AND DATE_TRUNC('week', NOW()) - INTERVAL '1 second'
     AND usd.itemtypebrand = 'pepe'
     AND cm."Brand" = 'pepe'
     AND cm.channel_type = 'B2C'
GROUP BY category_final
ORDER BY category_final

