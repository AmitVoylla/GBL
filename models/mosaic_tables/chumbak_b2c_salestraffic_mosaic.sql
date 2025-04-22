{{ config(
    materialized='table',
    indexes=[
        {'columns': ['"Date"', '"(Parent) ASIN"']},
    ]
) }}

WITH filtered_data AS (
   -- First, get the filtered dataset with DISTINCT ON applied
   SELECT DISTINCT ON (ciss.date, ciss.childasin, abm.product_name, abm.sku) 
       ciss.date,
       ciss.parentasin,
       ciss.childasin,
       abm.product_name,
       abm.sku,
       ciss.sessions,
       COALESCE(ciss.sessionsb2b, 0) AS sessionsb2b, 
       ciss.pageviews,
       COALESCE(ciss.pageviewsb2b, 0) AS pageviewsb2b,
       ciss.unitsordered,
       ciss.unitsorderedb2b,
       ciss.unitsessionpercentage,
       ciss.unitsessionpercentageb2b,
       ciss.orderedproductsales_amount,
       ciss.orderedproductsalesb2b_amount,
       ciss.totalorderitems,
       ciss.totalorderitemsb2b
   FROM public.chumbak_in_sellerpartner_salesandtrafficreportbychildasin ciss
   LEFT JOIN dbt_dsarkar."Asin_Brand_Mapping" abm
       ON ciss.parentasin = abm.asin 
   WHERE   
   ciss.date >= date_trunc('week', CURRENT_DATE) - INTERVAL '7 days'
  AND ciss.date < date_trunc('week', CURRENT_DATE)
),
daily_totals AS (
   -- Calculate the total sessions from this filtered dataset
   SELECT date, SUM(sessions) AS total_sessions, SUM(pageviews) AS total_pageviews
   FROM filtered_data
   GROUP BY date
),
daily_totals_b2b AS (
   -- Calculate the total B2B sessions and pageviews per day
   SELECT date, SUM(sessionsb2b) AS total_sessions_b2b, SUM(pageviewsb2b) AS total_pageviews_b2b
   FROM filtered_data
   GROUP BY date
)
SELECT
   f.date AS "Date",
   f.parentasin AS "(Parent) ASIN",
   f.childasin AS "(Child) ASIN",
   f.product_name AS "Title",
   f.sku AS "SKU",
   f.sessions AS "Sessions - Total",
   f.sessionsb2b AS "Sessions - Total - B2B",
   ROUND(
       CASE
           WHEN dt.total_sessions > 0 THEN (f.sessions * 100.0) / dt.total_sessions
           ELSE 0
       END, 2
   ) AS "Session Percentage - Total",
   ROUND(
       CASE
           WHEN dtb2b.total_sessions_b2b > 0 THEN (f.sessionsb2b * 100.0) / dtb2b.total_sessions_b2b
           ELSE 0
       END, 2
   ) AS "Session Percentage - Total - B2B",
   f.pageviews AS "Page Views - Total",
   f.pageviewsb2b AS "Page Views - Total - B2B",
   ROUND(
       CASE
           WHEN dt.total_pageviews > 0 THEN (f.pageviews * 100.0) / dt.total_pageviews
           ELSE 0
       END, 2
   ) AS "Page Views Percentage - Total",
   ROUND(
       CASE
           WHEN dtb2b.total_pageviews_b2b > 0 THEN (f.pageviewsb2b * 100.0) / dtb2b.total_pageviews_b2b
           ELSE 0
       END, 2
   ) AS "Page Views Percentage - Total - B2B",
   f.unitsordered AS "Units Ordered",
   f.unitsorderedb2b AS "Units Ordered - B2B",
   f.unitsessionpercentage as "Unit Session Percentage",
   f.unitsessionpercentageb2b as "Unit Session Percentage - B2B",
   f.orderedproductsales_amount AS "Ordered Product Sales",
   f.orderedproductsalesb2b_amount AS "Ordered Product Sales - B2B",
   f.totalorderitems AS "Total Order Items",
   f.totalorderitemsb2b AS "Total Order Items - B2B"
FROM filtered_data f
LEFT JOIN daily_totals dt
   ON f.date = dt.date
LEFT JOIN daily_totals_b2b dtb2b
   ON f.date = dtb2b.date


