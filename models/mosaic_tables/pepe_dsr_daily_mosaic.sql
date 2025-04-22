{{ config(
    materialized='table',
    indexes=[
        {'columns': ['"Source of Sales"']}
    ]
) }}


WITH amazon_vc_deduped AS (
   SELECT
       'Portal' AS "Source of Sales",
       'AMAZON_VC' AS "Portal",
       'NA' AS "Uniware Facility",
       cast(avf.startdate as Date) as "Date",
       CASE
           WHEN pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 'UG'
           WHEN pcsm."Clean Category" IN ('SLEEPWEAR', 'SOCKS', 'BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT') THEN 'Lounge Wear'
           WHEN pcsm."Clean Category" IN ('Women Active Pant','WOMEN SMU', 'Women Camisole', 'Women Hipster', 'Women Sleep Set', 'Women Tanktop', 'Women Trackpant', 'Women T-Shirt', 'LONG DRESS', 'SLEEP WEAR SET', 'DRESS') THEN 'Women''s Wear'
           ELSE 'Unknown'
       END AS "Super Cat",
       pcsm."Clean Category" AS "Clean Category",
       CASE
           WHEN pcsm.pcode = 'P4937' THEN 'BRIEF'
           WHEN pcsm.pcode = 'P10682' THEN 'GYM VEST'
           WHEN pcsm.pcode = 'P4478' THEN 'BOXER'
           WHEN pcsm.pcode IN ('P10341', 'P10972', 'P10861', 'P10855') THEN 'SOCKS'
           WHEN pcsm.pcode = 'P10790' THEN 'Women Sleep Set'
           WHEN pcsm.pcode = 'P1302' THEN 'BRIEF'
           WHEN pcsm.pcode = 'P4860' THEN 'TRUNK'
           ELSE uim.categoryname
       END AS "Category",
       avf.asin as "Channel Product ID",
       pcsm.pcode as "PCode",
       pcsm.ean as "EAN",
       avf.shippedunits as "Units Sold",
       avf.asp AS "GMV",
       avf.shippedunits * 0.90 AS "Net Unit",
       avf.revenue * 0.90 AS "Net Value",
       0.10 AS "RTV%",
       avf.revenue as "GMV Value",
       pcsm.mrp as "MRP",
       pcsm.mrp * avf.shippedunits as "MRP Value",
       round(((pcsm.mrp - avf.asp)/pcsm.mrp)*100, 2) AS "Discount %",
       pcsm.style as "Style",
       pcsm.colour as "Colour",
       pcsm.size as "Size",
       ROW_NUMBER() OVER (
       PARTITION BY
       pcsm.pcode,
       pcsm.ean,
       avf.shippedunits
       ORDER BY avf.startdate DESC) as rn
   FROM dbt_dsarkar.az_vc_data_final avf
   LEFT JOIN dbt_dsarkar.pepe_channel_sku_mapping pcsm
       ON avf.asin = pcsm.amazon
   LEFT JOIN dbt_dsarkar.uniware_itemmaster uim
       ON pcsm.pcode = uim.productcode AND uim.brand = 'pepe'
   WHERE avf.brand = 'Pepe'
       AND avf.startdate = CURRENT_DATE - INTERVAL '4 days'
       AND avf.shippedunits != 0
       AND avf.asp != 0
),
uniware_deduped AS (
   SELECT
       'UNIWARE' AS "Source of Sales",
       CASE
           WHEN usd.channelname IN ('AMAZON_IN_API', 'Cocoblu_BY78I_EXYC') THEN 'AMAZON'
           WHEN usd.channelname IN ('FLIPKART', 'FLIPKART_JAIPUR') THEN 'FLIPKART'
           WHEN usd.channelname = 'AJIO_DROPSHIP' THEN 'AJIO'
           WHEN usd.channelname = 'MEESHO_NEW' THEN 'MEESHO'
           WHEN usd.channelname = 'JIOMART' THEN 'JIOMART'
           WHEN usd.channelname = 'CRED' THEN 'CRED'
           WHEN usd.channelname = 'MYNTRAPPMP_New' THEN 'MYNTRA'
           ELSE 'OTHER'
       END AS "Portal",
       CASE
           WHEN usd.facility = 'PEPE JEANS INNERFASHION PRIVATE LIMITED' THEN 'PEPE_BANGALORE_FACILITY'
           WHEN usd.facility = 'PEPE_JAIPUR' THEN 'PEPE_JAIPUR_FACILITY'
           ELSE usd.facility
       END AS "Uniware Facility",
       CAST(usd.created AS DATE) AS "Date",
       CASE
           WHEN usd.category IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 'UG'
           WHEN usd.category IN ('SLEEPWEAR', 'SOCKS','BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT') THEN 'Lounge Wear'
           WHEN usd.category IN ('Women Active Pant','WOMEN SMU', 'Women Camisole', 'Women Hipster', 'Women Sleep Set', 'Women Tanktop', 'Women Trackpant', 'Women T-Shirt', 'LONG DRESS', 'SLEEP WEAR SET', 'DRESS') THEN 'Women''s Wear'
           ELSE 'Unknown'
       END AS "Super Cat",
       sku."Clean Category" AS "Clean Category",
       CASE
           WHEN sku.pcode = 'P4937' THEN 'BRIEF'
           WHEN sku.pcode = 'P10682' THEN 'GYM VEST'
           WHEN sku.pcode = 'P4478' THEN 'BOXER'
           WHEN sku.pcode IN ('P10341', 'P10972', 'P10861', 'P10855') THEN 'SOCKS'
           WHEN sku.pcode = 'P10790' THEN 'Women Sleep Set'
           WHEN sku.pcode = 'P1302' THEN 'BRIEF'
           WHEN sku.pcode = 'P4860' THEN 'TRUNK'
           ELSE uim.categoryname
       END AS "Category",
       CASE
           WHEN usd.channelname = 'MYNTRAPPMP_New' THEN sku.myntra
           WHEN usd.channelname IN ('AMAZON_IN_API', 'Cocoblu_BY78I_EXYC') THEN sku.amazon
           WHEN usd.channelname IN ('FLIPKART', 'FLIPKART_JAIPUR') THEN sku.flipkart
           ELSE usd.channelname
       END AS "Channel Product ID",
       sku.pcode as "PCode",
       sku.EAN AS "EAN",
       usd.quantity as "Units Sold",
       cast(usd.sellingprice as numeric) AS "GMV",
       usd.quantity * (1 -
           CASE
               WHEN usd.channelname IN ('FLIPKART', 'Flipkart_SOR_B2B', 'MYNTRAPPMP_New') THEN 0.15
               ELSE 0.10
           END
       ) AS "Net Unit",
       usd.quantity * cast(usd.sellingprice as numeric) * (1 -
           CASE
               WHEN usd.channelname IN ('FLIPKART', 'Flipkart_SOR_B2B', 'MYNTRAPPMP_New') THEN 0.15
               ELSE 0.10
           END
       ) AS "Net Value",
       CASE
           WHEN usd.channelname IN ('FLIPKART', 'Flipkart_SOR_B2B', 'MYNTRAPPMP_New') THEN 0.15
           ELSE 0.10
       END AS "RTV%",
       cast(usd.sellingprice as numeric) AS "GMV Value",
       sku.mrp as "MRP",
       (sku.mrp * usd.quantity) as "MRP Value",
       ROUND((usd.discount / NULLIF(usd.mrp, 0)) * 100, 2) AS "Discount %",
       sku.style as "Style",
       sku.colour as "Colour",
       sku.size as "Size",
       ROW_NUMBER() OVER (
           PARTITION BY
               sku.pcode,
               sku.EAN,
               usd.quantity,
               usd.channelname,
               usd.facility,
               usd.ordertime
           ORDER BY usd.ordertime DESC
       ) as rn
   FROM dbt_dsarkar.uniware_sales_data usd
   LEFT JOIN dbt_dsarkar.pepe_channel_sku_mapping sku
       ON usd.itemskucode = sku.Pcode
   LEFT JOIN dbt_dsarkar.uniware_itemmaster uim
       ON sku.pcode = uim.productcode AND uim.brand = 'pepe'
   WHERE usd.itemtypebrand = 'pepe'
       AND usd.saleorderitemstatus NOT IN ('CANCELLED', 'UNFULFILLABLE')
       AND cast(usd.created as date) = CURRENT_DATE - INTERVAL '1 day'
       AND usd.channelname IN ('MEESHO_NEW', 'FLIPKART', 'AJIO_DROPSHIP', 'AMAZON_IN_API', 'FLIPKART_JAIPUR', 'JIOMART', 'CRED', 'MYNTRAPPMP_New', 'Cocoblu_BY78I_EXYC')
),
blinkit_deduped as(
WITH deduped_pcsm AS (
 SELECT *
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY blinkit ORDER BY pcode) AS rn
   FROM dbt_dsarkar.pepe_channel_sku_mapping
 ) sub
 WHERE rn = 1
),
deduped_uim AS (
 SELECT *
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY productcode, brand ORDER BY productcode) AS rn
   FROM dbt_dsarkar.uniware_itemmaster
   WHERE brand = 'pepe'
 ) sub
 WHERE rn = 1
)
SELECT
  'Portal' AS "Source of Sales",
  'BLINKIT' AS "Portal",
  'NA' AS "Uniware Facility",
  CAST(qsf."date" AS DATE) AS "Date",
  CASE
      WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 'UG'
      WHEN deduped_pcsm."Clean Category" IN ('SLEEPWEAR', 'SOCKS','BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT') THEN 'Lounge Wear'
      WHEN deduped_pcsm."Clean Category" IN ('Women Active Pant', 'Women Camisole','WOMEN SMU', 'Women Hipster', 'Women Sleep Set', 'Women Tanktop', 'Women Trackpant', 'Women T-Shirt',  'LONG DRESS', 'SLEEP WEAR SET', 'DRESS') THEN 'Women''s Wear'
      ELSE 'Unknown'
  END AS "Super Cat",
  deduped_pcsm."Clean Category"  AS "Clean Category",
  CASE
      WHEN deduped_pcsm.pcode = 'P4937' THEN 'BRIEF'
      WHEN deduped_pcsm.pcode = 'P10682' THEN 'GYM VEST'
      WHEN deduped_pcsm.pcode = 'P4478' THEN 'BOXER'
      WHEN deduped_pcsm.pcode IN ('P10341', 'P10972', 'P10861', 'P10855') THEN 'SOCKS'
      WHEN deduped_pcsm.pcode = 'P10790' THEN 'Women Sleep Set'
      WHEN deduped_pcsm.pcode = 'P1302' THEN 'BRIEF'
      WHEN deduped_pcsm.pcode = 'P4860' THEN 'TRUNK'
      ELSE deduped_uim.categoryname
  END AS "Category",
  deduped_pcsm.blinkit AS "Channel Product ID",
  deduped_pcsm.pcode AS "PCode",
  deduped_pcsm.ean AS "EAN",
  qsf.units AS "Units Sold",
  ROUND(
      CASE
          WHEN qsf.units > 0 THEN
              (qsf.mrp - (qsf.mrp *
                  CASE
                      WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
                      WHEN deduped_pcsm."Clean Category" IN ('SLEEPWEAR', 'SOCKS','BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT') THEN 0.40
                      WHEN deduped_pcsm."Clean Category" IN ('Women Active Pant', 'Women Camisole','WOMEN SMU', 'Women Hipster', 'Women Sleep Set', 'Women Tanktop', 'Women Trackpant', 'Women T-Shirt',  'LONG DRESS', 'SLEEP WEAR SET', 'DRESS') THEN 0.10
                      ELSE 0.00
                  END
              )) / qsf.units
          ELSE NULL
      END, 2
  ) AS "GMV",
  qsf.units * 0.90 AS "Net Unit",
  (
      qsf.mrp - (qsf.mrp *
          CASE
              WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
              WHEN deduped_pcsm."Clean Category" IN ('SLEEPWEAR', 'SOCKS','BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT') THEN 0.40
              WHEN deduped_pcsm."Clean Category" IN ('Women Active Pant', 'Women Camisole','WOMEN SMU', 'Women Hipster', 'Women Sleep Set', 'Women Tanktop', 'Women Trackpant', 'Women T-Shirt',  'LONG DRESS', 'SLEEP WEAR SET', 'DRESS') THEN 0.10
              ELSE 0.00
          END
      )
  ) * 0.90 AS "Net Value",
  0.10 AS "RTV%",
  qsf.mrp - (qsf.mrp *
      CASE
          WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
          WHEN deduped_pcsm."Clean Category" IN ('SLEEPWEAR', 'SOCKS','BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT') THEN 0.40
          WHEN deduped_pcsm."Clean Category" IN ('Women Active Pant', 'Women Camisole','WOMEN SMU', 'Women Hipster', 'Women Sleep Set', 'Women Tanktop', 'Women Trackpant', 'Women T-Shirt',  'LONG DRESS', 'SLEEP WEAR SET', 'DRESS') THEN 0.10
          ELSE 0.00
      END
  ) AS "GMV Value",
  deduped_pcsm.mrp AS "MRP",
  deduped_pcsm.mrp * qsf.units as "MRP Value",
  CAST(
      CASE
          WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
          WHEN deduped_pcsm."Clean Category" IN ('SLEEPWEAR', 'SOCKS','BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET', 'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET', 'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP', 'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT') THEN 0.40
          WHEN deduped_pcsm."Clean Category" IN ('Women Active Pant', 'Women Camisole','WOMEN SMU', 'Women Hipster', 'Women Sleep Set', 'Women Tanktop', 'Women Trackpant', 'Women T-Shirt',  'LONG DRESS', 'SLEEP WEAR SET', 'DRESS') THEN 0.10
          ELSE 0.00
      END AS NUMERIC
  ) AS "Discount %",
  deduped_pcsm.style AS "Style",
  deduped_pcsm.colour AS "Colour",
  deduped_pcsm.size AS "Size"
FROM dbt_dsarkar.qcom_sales_final qsf
LEFT JOIN deduped_pcsm
  ON qsf.seller_sku = deduped_pcsm.blinkit
LEFT JOIN deduped_uim
  ON deduped_pcsm.pcode = deduped_uim.productcode
WHERE qsf.brand = 'Pepe Jeans'
AND qsf.channel = 'Blinkit'
AND qsf.date = CURRENT_DATE - INTERVAL '1 day'
),
swiggy_deduped AS (
WITH deduped_pcsm AS (
 SELECT *
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY swiggy ORDER BY pcode) AS rn
   FROM dbt_dsarkar.pepe_channel_sku_mapping
 ) sub
 WHERE rn = 1
),
deduped_uim AS (
 SELECT *
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY productcode, brand ORDER BY productcode) AS rn
   FROM dbt_dsarkar.uniware_itemmaster
   WHERE brand = 'pepe'
 ) sub
 WHERE rn = 1
)
SELECT
  'Portal' AS "Source of Sales",
  'SWIGGY' AS "Portal",
  'NA' AS "Uniware Facility",
  CAST(qsf."date" AS DATE) AS "Date",
  CASE
      WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 'UG'
      WHEN deduped_pcsm."Clean Category" IN (
          'SLEEPWEAR', 'SOCKS', 'BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET',
          'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET',
          'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP',
          'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT'
      ) THEN 'Lounge Wear'
      WHEN deduped_pcsm."Clean Category" IN (
          'Women Active Pant', 'Women Camisole', 'WOMEN SMU', 'Women Hipster', 'Women Sleep Set',
          'Women Tanktop', 'Women Trackpant', 'Women T-Shirt', 'LONG DRESS', 'SLEEP WEAR SET', 'DRESS'
      ) THEN 'Women''s Wear'
      ELSE 'Unknown'
  END AS "Super Cat",
  deduped_pcsm."Clean Category"  AS "Clean Category",
     CASE
   WHEN deduped_pcsm.pcode = 'P4937' THEN 'BRIEF'
   WHEN deduped_pcsm.pcode = 'P10682' THEN 'GYM VEST'
   WHEN deduped_pcsm.pcode = 'P4478' THEN 'BOXER'
   WHEN deduped_pcsm.pcode IN ('P10341', 'P10972', 'P10861', 'P10855') THEN 'SOCKS'
   WHEN deduped_pcsm.pcode = 'P10790' THEN 'Women Sleep Set'
   WHEN deduped_pcsm.pcode = 'P1302' THEN 'BRIEF'
   WHEN deduped_pcsm.pcode = 'P4860' THEN 'TRUNK'
   ELSE deduped_uim.categoryname
END AS "Category",
  deduped_pcsm.swiggy AS "Channel Product ID",
  deduped_pcsm.pcode AS "PCode",
  deduped_pcsm.ean AS "EAN",
  qsf.units AS "Units Sold",
  -- GMV
  (qsf.mrp - (qsf.mrp *
      CASE
          WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
          WHEN deduped_pcsm."Clean Category" IN (
              'SLEEPWEAR', 'SOCKS', 'BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET',
              'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET',
              'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP',
              'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT'
          ) THEN 0.40
          WHEN deduped_pcsm."Clean Category" IN (
              'Women Active Pant', 'Women Camisole', 'WOMEN SMU', 'Women Hipster', 'Women Sleep Set',
              'Women Tanktop', 'Women Trackpant', 'Women T-Shirt', 'LONG DRESS', 'SLEEP WEAR SET', 'DRESS'
          ) THEN 0.10
          ELSE 0.00
      END
  )) AS "GMV",
  -- Net Units
  qsf.units * (1 - 0.10) AS "Net Unit",
  -- Net Value
  (
      qsf.mrp - (qsf.mrp *
          CASE
              WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
              WHEN deduped_pcsm."Clean Category" IN (
                  'SLEEPWEAR', 'SOCKS', 'BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET',
                  'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET',
                  'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP',
                  'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT'
              ) THEN 0.40
              WHEN deduped_pcsm."Clean Category" IN (
                  'Women Active Pant', 'Women Camisole', 'WOMEN SMU', 'Women Hipster', 'Women Sleep Set',
                  'Women Tanktop', 'Women Trackpant', 'Women T-Shirt', 'LONG DRESS', 'SLEEP WEAR SET', 'DRESS'
              ) THEN 0.10
              ELSE 0.00
          END
      )
  ) * (1 - 0.10) AS "Net Value",
  0.10 AS "RTV%",
  -- GMV Value
  qsf.units *
  (qsf.mrp - (qsf.mrp *
      CASE
          WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
          WHEN deduped_pcsm."Clean Category" IN (
              'SLEEPWEAR', 'SOCKS', 'BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET',
              'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET',
              'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP',
              'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT'
          ) THEN 0.40
          WHEN deduped_pcsm."Clean Category" IN (
              'Women Active Pant', 'Women Camisole', 'WOMEN SMU', 'Women Hipster', 'Women Sleep Set',
              'Women Tanktop', 'Women Trackpant', 'Women T-Shirt', 'LONG DRESS', 'SLEEP WEAR SET', 'DRESS'
          ) THEN 0.10
          ELSE 0.00
      END
  )) AS "GMV Value",
  deduped_pcsm.mrp AS "MRP",
  deduped_pcsm.mrp*qsf.units as "MRP Value",
  -- Discount %
  CAST(
      CASE
          WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 0.15
          WHEN deduped_pcsm."Clean Category" IN (
              'SLEEPWEAR', 'SOCKS', 'BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET',
              'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET',
              'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP',
              'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT'
          ) THEN 0.40
          WHEN deduped_pcsm."Clean Category" IN (
              'Women Active Pant', 'Women Camisole', 'WOMEN SMU', 'Women Hipster', 'Women Sleep Set',
              'Women Tanktop', 'Women Trackpant', 'Women T-Shirt', 'LONG DRESS', 'SLEEP WEAR SET', 'DRESS'
          ) THEN 0.10
          ELSE 0.00
      END AS NUMERIC
  ) AS "Discount %",
  deduped_pcsm.style AS "Style",
  deduped_pcsm.colour AS "Colour",
  deduped_pcsm.size AS "Size",
     ROW_NUMBER() OVER (
           PARTITION BY
               deduped_pcsm.pcode,
               deduped_pcsm.EAN,
               qsf.units,
               qsf.channel
           ORDER BY qsf.date DESC
       ) as rn
FROM dbt_dsarkar.qcom_sales_final qsf
LEFT JOIN deduped_pcsm
  ON qsf.seller_sku = deduped_pcsm.swiggy
LEFT JOIN deduped_uim
  ON deduped_pcsm.pcode = deduped_uim.productcode AND deduped_uim.brand = 'pepe'
WHERE qsf.brand = 'Pepe Jeans'
AND qsf.channel = 'Instamart'
 AND qsf.date = CURRENT_DATE - INTERVAL '2 days'
),
zepto_deduped AS (
WITH deduped_pcsm AS (
 SELECT *
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY swiggy ORDER BY pcode) AS rn
   FROM dbt_dsarkar.pepe_channel_sku_mapping
 ) sub
 WHERE rn = 1
),
deduped_uim AS (
 SELECT *
 FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY productcode, brand ORDER BY productcode) AS rn
   FROM dbt_dsarkar.uniware_itemmaster
   WHERE brand = 'pepe'
 ) sub
 WHERE rn = 1
)
SELECT
  'Portal' AS "Source of Sales",
  'ZEPTO' AS "Portal",
  'NA' AS "Uniware Facility",
  CAST(qsf."date" AS DATE) AS "Date",
  CASE
      WHEN deduped_pcsm."Clean Category" IN ('BASIS VEST', 'Vest', 'VEST', 'BRIEF', 'TRUNK') THEN 'UG'
      WHEN deduped_pcsm."Clean Category" IN (
          'SLEEPWEAR', 'SOCKS','BERMUDA', 'BOXER', 'SATIN BOXER', 'BLACK GOLD SLEEPWEAR SET',
          'CLASSIC SLEEPWEAR PYJAMA', 'THERMAL', 'CLASSIC SLEEPWEAR SET', 'ONLY PLAY SLEEPWEAR SET',
          'PYJAMA', 'GYM VEST', 'SHORTS', 'Socks', 'THERMAL BOTTOM', 'THERMAL TOP',
          'THERMAL TOP AND BOTTOM', 'TRACK PANT', 'TRACKSUIT', 'T-SHIRT'
      ) THEN 'Lounge Wear'
      WHEN deduped_pcsm."Clean Category" IN (
          'Women Active Pant', 'Women Camisole','WOMEN SMU', 'Women Hipster', 'Women Sleep Set',
          'Women Tanktop', 'Women Trackpant', 'Women T-Shirt',  'LONG DRESS', 'SLEEP WEAR SET', 'DRESS'
      ) THEN 'Women''s Wear'
      ELSE 'Unknown'
  END AS "Super Cat",
  deduped_pcsm."Clean Category"  AS "Clean Category",
  CASE
      WHEN deduped_pcsm.pcode = 'P4937' THEN 'BRIEF'
      WHEN deduped_pcsm.pcode = 'P10682' THEN 'GYM VEST'
      WHEN deduped_pcsm.pcode = 'P4478' THEN 'BOXER'
      WHEN deduped_pcsm.pcode IN ('P10341', 'P10972', 'P10861', 'P10855') THEN 'SOCKS'
      WHEN deduped_pcsm.pcode = 'P10790' THEN 'Women Sleep Set'
      WHEN deduped_pcsm.pcode = 'P1302' THEN 'BRIEF'
      WHEN deduped_pcsm.pcode = 'P4860' THEN 'TRUNK'
      ELSE deduped_uim.categoryname
  END AS "Category",
  deduped_pcsm.zepto AS "Channel Product ID",
  deduped_pcsm.pcode AS "PCode",
  deduped_pcsm.ean AS "EAN",
  qsf.units AS "Units Sold",
  qsf.selling_price / qsf.units AS "GMV",
  qsf.units * (1 - 0.10) AS "Net Unit",
  (qsf.selling_price / qsf.units) * (1 - 0.10) AS "Net Value",
  0.10 AS "RTV%",
  qsf.selling_price AS "GMV Value",
  deduped_pcsm.mrp AS "MRP",
  deduped_pcsm.mrp * qsf.units AS "MRP Value",
  ROUND(((deduped_pcsm.mrp - qsf.selling_price) / deduped_pcsm.mrp), 2) AS "Discount %",
  deduped_pcsm.style AS "Style",
  deduped_pcsm.colour AS "Colour",
  deduped_pcsm.size AS "Size",
  ROW_NUMBER() OVER (
      PARTITION BY
          deduped_pcsm.pcode,
          deduped_pcsm.EAN,
          qsf.units,
          qsf.channel
      ORDER BY qsf.date DESC
  ) AS rn
FROM dbt_dsarkar.qcom_sales_final qsf
LEFT JOIN deduped_pcsm
  ON qsf.seller_sku = deduped_pcsm.zepto
LEFT JOIN deduped_uim
  ON deduped_pcsm.pcode = deduped_uim.productcode AND deduped_uim.brand = 'pepe'
WHERE qsf.brand = 'Pepe Jeans'
 AND qsf.channel = 'Zepto'
 AND qsf.date = CURRENT_DATE - INTERVAL '1 day'
 AND qsf.units > 0
 AND deduped_pcsm.mrp > 0
)
-- Amazon VC results
SELECT
   "Source of Sales", "Portal", "Uniware Facility", "Date", "Super Cat",
   "Clean Category", "Category", "Channel Product ID", "PCode", "EAN",
   "Units Sold", "GMV", "Net Unit", "Net Value", "RTV%", "GMV Value",
   "MRP", "MRP Value", "Discount %", "Style", "Colour", "Size"
FROM amazon_vc_deduped
WHERE rn = 1
UNION ALL
-- Uniware results
SELECT
   "Source of Sales", "Portal", "Uniware Facility", "Date", "Super Cat",
   "Clean Category", "Category", "Channel Product ID", "PCode", "EAN",
   "Units Sold", "GMV", "Net Unit", "Net Value", "RTV%", "GMV Value",
   "MRP", "MRP Value", "Discount %", "Style", "Colour", "Size"
FROM uniware_deduped
WHERE rn = 1
UNION all
SELECT
   "Source of Sales", "Portal", "Uniware Facility", "Date", "Super Cat",
   "Clean Category", "Category", "Channel Product ID", "PCode", "EAN",
   "Units Sold", "GMV", "Net Unit", "Net Value", "RTV%", "GMV Value",
   "MRP", "MRP Value", "Discount %", "Style", "Colour", "Size"
FROM blinkit_deduped
UNION all
SELECT
   "Source of Sales", "Portal", "Uniware Facility", "Date", "Super Cat",
   "Clean Category", "Category", "Channel Product ID", "PCode", "EAN",
   "Units Sold", "GMV", "Net Unit", "Net Value", "RTV%", "GMV Value",
   "MRP", "MRP Value", "Discount %", "Style", "Colour", "Size"
FROM swiggy_deduped
UNION all
SELECT
   "Source of Sales", "Portal", "Uniware Facility", "Date", "Super Cat",
   "Clean Category", "Category", "Channel Product ID", "PCode", "EAN",
   "Units Sold", "GMV", "Net Unit", "Net Value", "RTV%", "GMV Value",
   "MRP", "MRP Value", "Discount %", "Style", "Colour", "Size"
FROM zepto_deduped
 
