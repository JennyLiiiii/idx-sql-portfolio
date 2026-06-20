-- ============================================================
-- IDX Exchange - Internship
-- Week 4: queries
-- Tables: rets_property, rets_openhouse, california_sold
-- Author: Jenny
-- ============================================================

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

-- BROKEN: Average list price by city for listings with open houses
-- Results are higher than expected — why?
SELECT p.L_City,
	   COUNT(*) AS listing_count,
	   ROUND(AVG(p.L_SystemPrice), 0) AS avg_price
FROM rets_property p
INNER JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
GROUP BY p.L_City
ORDER BY avg_price DESC
LIMIT 15;

-- Debug
SELECT rp.L_City,
	   COUNT(DISTINCT rp.L_DisplayId) AS listing_count,
	   ROUND(AVG(rp.L_SystemPrice), 0) AS avg_price
FROM rets_property rp
INNER JOIN(
	SELECT DISTINCT L_DisplayId
	FROM rets_property rp
) ro ON rp.L_DisplayId = ro.L_DisplayId
GROUP BY rp.L_City
ORDER BY avg_price DESC
LIMIT 15;