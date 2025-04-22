{{ config(
    materialized='table',
    indexes = [
        {'columns':['brand','adtype']}
    ]
) }} 

WITH weekly_data AS (
    SELECT
        reportdate,
        brand,
        adtype,
        impressions,
        clicks,
        cost AS spends,
        attributedunitsorderd AS orders,
        attributedsales AS sales,
        DATE_TRUNC('week', reportdate) - INTERVAL '1 day' AS week_start  -- Week ends on Sunday
    FROM dbt_dsarkar.az_total_ads_final
),

latest_weeks AS (
    SELECT week_start
    FROM (
        SELECT 
            (SELECT MAX(week_start) FROM weekly_data WHERE week_start <= CURRENT_DATE - INTERVAL '1 day') - INTERVAL '1 week' AS current_week,
            (SELECT MAX(week_start) FROM weekly_data WHERE week_start <= CURRENT_DATE - INTERVAL '1 day') - INTERVAL '2 weeks' AS previous_week
        ) t
    CROSS JOIN LATERAL (VALUES (current_week), (previous_week)) AS weeks(week_start)
),

aggregated_weekly AS (
    SELECT
        wd.brand,
        wd.adtype,
        wd.week_start,
        SUM(COALESCE(wd.impressions, 0)) AS impressions,
        SUM(COALESCE(wd.clicks, 0)) AS clicks,
        SUM(COALESCE(wd.spends, 0)) AS spends,
        SUM(COALESCE(wd.orders, 0)) AS orders,
        SUM(COALESCE(wd.sales, 0)) AS sales
    FROM weekly_data wd
    JOIN latest_weeks lw ON wd.week_start = lw.week_start
    GROUP BY wd.brand, wd.adtype, wd.week_start
),

pivoted_weeks AS (
    SELECT
        brand,
        adtype,
        COALESCE(MAX(CASE WHEN week_start = (SELECT MAX(week_start) FROM latest_weeks) THEN impressions END), 0) AS "Current Week Impressions",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MIN(week_start) FROM latest_weeks) THEN impressions END), 0) AS "Previous Week Impressions",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MAX(week_start) FROM latest_weeks) THEN clicks END), 0) AS "Current Week Clicks",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MIN(week_start) FROM latest_weeks) THEN clicks END), 0) AS "Previous Week Clicks",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MAX(week_start) FROM latest_weeks) THEN spends END), 0) AS "Current Week Spends",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MIN(week_start) FROM latest_weeks) THEN spends END), 0) AS "Previous Week Spends",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MAX(week_start) FROM latest_weeks) THEN orders END), 0) AS "Current Week Orders",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MIN(week_start) FROM latest_weeks) THEN orders END), 0) AS "Previous Week Orders",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MAX(week_start) FROM latest_weeks) THEN sales END), 0) AS "Current Week Sales",
        COALESCE(MAX(CASE WHEN week_start = (SELECT MIN(week_start) FROM latest_weeks) THEN sales END), 0) AS "Previous Week Sales"
    FROM aggregated_weekly
    GROUP BY brand, adtype
),

final_calculations AS (
    SELECT
        CURRENT_DATE AS report_date,  -- Added current date field
        brand,
        adtype,
        "Previous Week Impressions", "Current Week Impressions",
        ROUND(("Current Week Impressions" - "Previous Week Impressions") * 100.0 / NULLIF("Previous Week Impressions", 0), 2) AS "Impressions Change (%)",
        "Previous Week Clicks", "Current Week Clicks",
        ROUND(("Current Week Clicks" - "Previous Week Clicks") * 100.0 / NULLIF("Previous Week Clicks", 0), 2) AS "Clicks Change (%)",
        "Previous Week Spends", "Current Week Spends",
        ROUND(("Current Week Spends" - "Previous Week Spends") * 100.0 / NULLIF("Previous Week Spends", 0), 2) AS "Spends Change (%)",
        "Previous Week Orders", "Current Week Orders",
        ROUND(("Current Week Orders" - "Previous Week Orders") * 100.0 / NULLIF("Previous Week Orders", 0), 2) AS "Orders Change (%)",
        "Previous Week Sales", "Current Week Sales",
        ROUND(("Current Week Sales" - "Previous Week Sales") * 100.0 / NULLIF("Previous Week Sales", 0), 2) AS "Sales Change (%)",
        ROUND("Previous Week Clicks" * 100.0 / NULLIF("Previous Week Impressions", 0), 2) AS "Previous Week CTR (%)",
        ROUND("Current Week Clicks" * 100.0 / NULLIF("Current Week Impressions", 0), 2) AS "Current Week CTR (%)",
        ROUND(("Current Week Clicks" * 100.0 / NULLIF("Current Week Impressions", 0)) - ("Previous Week Clicks" * 100.0 / NULLIF("Previous Week Impressions", 0)), 2) AS "CTR Change (%)",
        ROUND("Previous Week Orders" * 100.0 / NULLIF("Previous Week Clicks", 0), 2) AS "Previous Week CR (%)",
        ROUND("Current Week Orders" * 100.0 / NULLIF("Current Week Clicks", 0), 2) AS "Current Week CR (%)",
        ROUND(("Current Week Orders" * 100.0 / NULLIF("Current Week Clicks", 0)) - ("Previous Week Orders" * 100.0 / NULLIF("Previous Week Clicks", 0)), 2) AS "CR Change (%)",
        ROUND("Previous Week Spends" / NULLIF("Previous Week Clicks", 0), 2) AS "Previous Week CPC",
        ROUND("Current Week Spends" / NULLIF("Current Week Clicks", 0), 2) AS "Current Week CPC",
        ROUND(("Current Week Spends" / NULLIF("Current Week Clicks", 0)) - ("Previous Week Spends" / NULLIF("Previous Week Clicks", 0)), 2) AS "CPC Change (%)",
        ROUND("Previous Week Spends" * 100.0 / NULLIF("Previous Week Sales", 0), 2) AS "Previous Week ACOS (%)",
        ROUND("Current Week Spends" * 100.0 / NULLIF("Current Week Sales", 0), 2) AS "Current Week ACOS (%)",
        ROUND(("Current Week Spends" * 100.0 / NULLIF("Current Week Sales", 0)) - ("Previous Week Spends" * 100.0 / NULLIF("Previous Week Sales", 0)), 2) AS "ACOS Change (%)"
    FROM pivoted_weeks
)

SELECT * FROM final_calculations
ORDER BY brand, adtype