{{ config(
    materialized='table',
    indexes=[
        {'columns': ['category_final']}
    ]
) }}

SELECT
   category_final,
   mapped_channel AS "Channel",  -- Fetch mapped_channel from subquery
   CASE
       WHEN sellingprice < range_min THEN '<' || range_min
       WHEN sellingprice BETWEEN range_min AND range_max THEN range_min || '-' || range_max
       WHEN sellingprice > range_max THEN '>' || range_max
   END AS "Range",
   ROUND(
       (COALESCE(SUM(sellingprice), 0) * 100.0) 
       / NULLIF(SUM(COALESCE(SUM(sellingprice), 0)) OVER (PARTITION BY category_final, mapped_channel), 0), 1
   ) AS "Percentage"
FROM (
   SELECT
       CASE
           WHEN category IN ('BASIS VEST', 'Vest') THEN 'VEST'
           WHEN category IN ('BERMUDA', 'BOXER', 'SATIN BOXER') THEN 'BOXER'
           WHEN category IN ('BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'CLASSIC SLEEPWEAR SET', 'DRESS', 'LONG DRESS', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'SLEEP WEAR SET') THEN 'SLEEPWEAR'
           WHEN category = 'BRIEF' THEN 'BRIEF'
           WHEN category = 'GYM VEST' THEN 'GYM VEST'
           WHEN category = 'SHORTS' THEN 'SHORTS'
           WHEN category = 'Socks' THEN 'SOCKS'
           WHEN category IN ('THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM') THEN 'THERMAL'
           WHEN category = 'TRACK PANT' THEN 'TRACK PANT'
           WHEN category = 'TRACKSUIT' THEN 'TRACKSUIT'
           WHEN category = 'TRUNK' THEN 'TRUNK'
           WHEN category = 'T-SHIRT' THEN 'T-SHIRT'
           WHEN category = 'Women Active Pant' THEN 'Women Active Pant'
           WHEN category IN ('Women Camisole') THEN 'Women Camisole'
           WHEN category = 'Women Hipster' THEN 'Women Hipster'
           WHEN category IN ('Women Sleep Set', 'Women Tanktop', 'Women Trackpant') THEN 'WOMEN SMU'
           WHEN category = 'Women T-Shirt' THEN 'Women T-Shirt'
           ELSE 'Unknown'
       END AS category_final,
       cm.mapped_channel,  -- Use mapped_channel to avoid second join
       CAST(sellingprice AS NUMERIC) AS sellingprice,
       CASE
           WHEN category IN ('BASIS VEST', 'Vest') THEN 300
           WHEN category IN ('BERMUDA', 'BOXER', 'SATIN BOXER') THEN 300
           WHEN category IN ('BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'CLASSIC SLEEPWEAR SET', 'DRESS', 'LONG DRESS', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'SLEEP WEAR SET') THEN 450
           WHEN category = 'BRIEF' THEN 200
           WHEN category = 'GYM VEST' THEN 300
           WHEN category = 'SHORTS' THEN 300
           WHEN category = 'Socks' THEN 200
           WHEN category IN ('THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM') THEN 250
           WHEN category = 'TRACK PANT' THEN 500
           WHEN category = 'TRACKSUIT' THEN 1050
           WHEN category = 'TRUNK' THEN 200
           WHEN category = 'T-SHIRT' THEN 450
           WHEN category = 'Women Active Pant' THEN 850
           WHEN category IN ('Women Camisole') THEN 350
           WHEN category = 'Women Hipster' THEN 450
           WHEN category IN ('Women Sleep Set', 'Women Tanktop', 'Women Trackpant') THEN 750
           WHEN category = 'Women T-Shirt' THEN 700
           ELSE NULL
       END AS range_min,
       CASE
           WHEN category IN ('BASIS VEST', 'Vest') THEN 350
           WHEN category IN ('BERMUDA', 'BOXER', 'SATIN BOXER') THEN 350
           WHEN category IN ('BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'CLASSIC SLEEPWEAR SET', 'DRESS', 'LONG DRESS', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'SLEEP WEAR SET') THEN 650
           WHEN category = 'BRIEF' THEN 300
           WHEN category = 'GYM VEST' THEN 350
           WHEN category = 'SHORTS' THEN 400
           WHEN category = 'Socks' THEN 400
           WHEN category IN ('THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM') THEN 400
           WHEN category = 'TRACK PANT' THEN 700
           WHEN category = 'TRACKSUIT' THEN 1200
           WHEN category = 'TRUNK' THEN 300
           WHEN category = 'T-SHIRT' THEN 500
           WHEN category = 'Women Active Pant' THEN 950
           WHEN category IN ('Women Camisole') THEN 400
           WHEN category = 'Women Hipster' THEN 500
           WHEN category IN ('Women Sleep Set', 'Women Tanktop', 'Women Trackpant') THEN 850
           WHEN category = 'Women T-Shirt' THEN 750
           ELSE NULL
       END AS range_max
   FROM dbt_dsarkar.uniware_sales_all_data usd
   LEFT JOIN dbt_dsarkar.channel_mapping_sheet cm
       ON usd.channelname = cm.channelname  -- Keep only one join
   WHERE CAST(usd.created AS DATE)  
          BETWEEN DATE_TRUNC('week', NOW()) - INTERVAL '7 days' 
       AND DATE_TRUNC('week', NOW()) - INTERVAL '1 second'
     AND usd.itemtypebrand = 'pepe'
     AND cm."Brand" = 'pepe'
     AND cm.channel_type = 'B2C'
) subquery
GROUP BY category_final, mapped_channel, range_min, range_max, "Range"
ORDER BY category_final
