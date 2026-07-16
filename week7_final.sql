-- ============================================================
-- IDX Exchange - Data Analyst Internship
-- Week 7: Final Open-Ended Challenge
-- Tables: rets_property, california_sold
-- Author: Jenny Li
-- ============================================================

/*
Market label definitions:

1. Competitive Market
   Average historical sale-to-list ratio is at least 1.02.
   This means properties sold, on average, for at least 2% above
   their historical listing prices.

2. Buyer Opportunity
   Average historical sale-to-list ratio is at most 0.98.
   This means properties sold, on average, for at least 2% below
   their historical listing prices.

3. Balanced Market
   Average historical sale-to-list ratio is between 0.98 and 1.02.
   A +/- 2% range is used so that small price differences are not
   treated as meaningful market changes.

Sale-to-list ratio:
   Average of ClosePrice / ListPrice for valid historical sales.
   
Major city definition:
   The 20 cities with the largest number of active listings.
*/

WITH open_house_by_listing AS (
    SELECT
        L_DisplayId,
        COUNT(*) AS open_house_events
    FROM rets_openhouse
    WHERE L_DisplayId IS NOT NULL
    GROUP BY L_DisplayId
),

active_listing_base AS (
	SELECT DISTINCT
	        rp.L_DisplayId,
	        LOWER(TRIM(rp.L_City)) AS city_key,
	        TRIM(rp.L_City) AS city,
	        rp.L_SystemPrice AS active_price,
	        COALESCE(ro.open_house_events, 0) AS open_house_events
	    FROM rets_property AS rp
	    LEFT JOIN open_house_by_listing AS ro
	        ON rp.L_DisplayId = ro.L_DisplayId
	    WHERE rp.L_DisplayId IS NOT NULL
	      AND rp.L_City IS NOT NULL
	      AND TRIM(rp.L_City) <> ''
	      AND rp.L_SystemPrice IS NOT NULL
	      AND rp.L_SystemPrice > 0
),

active_city_summary AS (
    SELECT
        city_key,
        MIN(city) AS city,
        COUNT(DISTINCT L_DisplayId) AS active_listings,
        AVG(active_price) AS avg_active_price,
        SUM(open_house_events) AS open_house_events
    FROM active_listing_base
    GROUP BY city_key
),

sold_city_summary AS (
    SELECT
        LOWER(TRIM(City)) AS city_key,
        AVG(ClosePrice) AS avg_historical_sold_price,
        AVG(ClosePrice / NULLIF(ListPrice, 0)) AS sale_to_list_ratio,
        COUNT(*) AS historical_sales
    FROM california_sold
    WHERE City IS NOT NULL
      AND TRIM(City) <> ''
      AND ListPrice IS NOT NULL
      AND ListPrice > 0
      AND ClosePrice IS NOT NULL
      AND ClosePrice > 0
    GROUP BY LOWER(TRIM(City))
),

combined_city_summary AS (
    SELECT
        a.city,
        a.active_listings,
        a.avg_active_price,
        s.avg_historical_sold_price,
        s.sale_to_list_ratio,
        a.open_house_events
    FROM active_city_summary AS a
    INNER JOIN sold_city_summary AS s
        ON a.city_key = s.city_key
    WHERE s.historical_sales >= 10
),


ranked_cities AS (
    SELECT
        city,
        active_listings,
        avg_active_price,
        avg_historical_sold_price,
        sale_to_list_ratio,

        ROW_NUMBER() OVER (
            ORDER BY
                active_listings DESC,
                open_house_events DESC,
                city
        ) AS major_city_rank

    FROM combined_city_summary
)

SELECT
    city,
    active_listings,
    ROUND(avg_active_price, 2) AS avg_active_price,
    ROUND(avg_historical_sold_price, 2) AS avg_historical_sold_price,
    ROUND(sale_to_list_ratio * 100, 2) AS sale_to_list_ratio_pct,

    CASE
        WHEN sale_to_list_ratio >= 1.02
            THEN 'Competitive Market'

        WHEN sale_to_list_ratio <= 0.98
            THEN 'Buyer Opportunity'

        ELSE 'Balanced Market'
    END AS market_label

FROM ranked_cities
WHERE major_city_rank <= 20
ORDER BY major_city_rank;
