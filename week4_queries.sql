-- ============================================================
-- IDX Exchange - Data Analyst Internship
-- Week 4: Multi-Table Analysis with JOINs
-- Tables: rets_property, rets_openhouse
-- Author: Jenny Li
-- ============================================================

-- OPEN-HOUSE CAMPAIGN RECOMMENDATION
-- Los Angeles, San Diego, and San Jose have the highest observed open-house
-- volumes in the exported city summary, so they are the strongest initial
-- markets for an event campaign. Schedule events on the highest-volume weekend
-- day returned by the day-of-week query, then validate results with attendance.

-- INNER JOIN: only listings that HAVE at least one open house
SELECT rp.L_DisplayId, rp.L_Address, rp.L_City, rp.L_SystemPrice,
	   ro.OpenHouseDate, ro.OH_StartTime, ro.OH_EndTime
FROM rets_property rp 
INNER JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId 
ORDER BY ro.OpenHouseDate 
LIMIT 20;

-- LEFT JOIN: ALL listings, NULL for open house fields if none exist
SELECT rp.L_DisplayId, rp.L_Address, ro.OpenHouseDate
FROM rets_property rp
LEFT JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
LIMIT 10;

-- Count open house per listing
SELECT rp.L_DisplayId, rp.L_Address, rp.L_City, rp.L_SystemPrice,
	   COUNT(ro.OpenHouseDate) AS num_open_houses
FROM rets_property rp
INNER JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
GROUP BY rp.L_DisplayId, rp.L_Address, rp.L_City, rp.L_SystemPrice
ORDER BY num_open_houses DESC
LIMIT 20;

-- What percentage have open house?
SELECT
	COUNT(DISTINCT rp.L_DisplayId) AS total_listings,
	COUNT(DISTINCT ro.L_DisplayId) AS listings_with_openhouse,
	ROUND(100.0 * COUNT(DISTINCT ro.L_DisplayId)
		  / COUNT(DISTINCT rp.L_DisplayId), 1) AS pct_with_openhouse
FROM rets_property rp
LEFT JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId;

-- Open house activity by city
SELECT rp.L_City,
	   COUNT(DISTINCT rp.L_DisplayId) AS total_listings,
	   COUNT(ro.OpenHouseDate) AS total_open_houses,
 	   ROUND(100.0 * COUNT(DISTINCT ro.L_DisplayId)
			/ COUNT(DISTINCT rp.L_DisplayId), 1) AS pct_with_openhouse
FROM rets_property rp
LEFT JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
GROUP BY rp.L_City
HAVING COUNT(DISTINCT rp.L_DisplayId) >= 10
ORDER BY total_open_houses DESC
LIMIT 20;

-- Most popular open house date
SELECT 
	DAYNAME(OpenHouseDate) AS day_of_week,
	COUNT(*) AS num_open_houses
FROM rets_openhouse
WHERE OpenHouseDate IS NOT NULL
GROUP BY DAYNAME(OpenHouseDate), DAYOFWEEK(OpenHouseDate)
ORDER BY DAYOFWEEK(OpenHouseDate);

-- BROKEN: Average list price by city for listings with open houses.
-- The original query joined directly to every rets_openhouse row before AVG().

-- DEBUG NOTES:
-- The guide's original query runs, but its result is logically wrong: a listing
-- with several open houses appears several times after the join and therefore
-- receives extra weight in COUNT(*) and AVG(). I diagnosed the silent bug by
-- comparing COUNT(*) with COUNT(DISTINCT p.L_DisplayId). Fixed: deduplicate the
-- open-house listing IDs before joining so each property contributes once.

-- FIXED:
WITH listings_with_open_houses AS (
    SELECT DISTINCT
        L_DisplayId
    FROM rets_openhouse
)
SELECT
    p.L_City,
    COUNT(*) AS listing_count,
    ROUND(AVG(p.L_SystemPrice), 0) AS avg_price
FROM rets_property p
INNER JOIN listings_with_open_houses o
    ON p.L_DisplayId = o.L_DisplayId
WHERE p.L_SystemPrice IS NOT NULL
GROUP BY p.L_City
ORDER BY avg_price DESC
LIMIT 15;
