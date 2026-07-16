-- ============================================================
-- IDX Exchange - Data Analyst Internship
-- Week 7: Final Open-Ended Challenge
-- Tables: rets_property, california_sold
-- Author: Jenny Li
-- ============================================================

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




