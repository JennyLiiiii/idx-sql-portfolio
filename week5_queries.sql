-- ============================================================
-- IDX Exchange - Data Analyst Internship
-- Week 5: Subqueries and CTEs
-- Tables: rets_property, california_sold
-- Author: Jenny Li
-- ============================================================

-- SACRAMENTO SELLER RECOMMENDATION
-- Sacramento's historical sale-to-list ratio is about 100.8%, while the active
-- average list price ($464,660) is below the historical average sold price
-- ($503,196). This supports listing now, but pricing should stay close to recent
-- comparables rather than assuming that every property will sell above asking.

-- Find listings priced above the overall average
SELECT L_Address, L_City, L_SystemPrice
FROM rets_property
WHERE L_SystemPrice > (
SELECT AVG(L_SystemPrice) FROM rets_property
)
ORDER BY L_SystemPrice DESC LIMIT 20;

-- 5.1 Explore california_sold
SELECT City,
	COUNT(*) AS total_sold,
	ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
	ROUND(AVG(ListPrice), 0) AS avg_list_price,
	ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS avg_sale_to_list_pct
FROM california_sold
WHERE ClosePrice IS NOT NULL AND ListPrice > 0
GROUP BY City
HAVING COUNT(*) >= 10
ORDER BY avg_sale_to_list_pct DESC
LIMIT 20;
-- Seems like most of them sold for more than asking

-- CTEs Common Table Expressions: Cities where active listings are significantly above historical norms.
-- I define “significantly above historical norms” as cities where the average active listing price is 
-- more than 30% above the historical average sold price.
WITH historical_avg AS (
	SELECT City,
		   ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
		   COUNT(*) AS num_sold
	FROM california_sold cs 
	WHERE ClosePrice IS NOT NULL
	GROUP BY City 
	HAVING COUNT(*) >= 10
)
SELECT rp.L_City,
	COUNT(DISTINCT rp.L_DisplayId) AS active_listings,
	ROUND(AVG(rp.L_SystemPrice), 0) AS avg_active_price,
	h.avg_sold_price,
	ROUND((AVG(rp.L_SystemPrice) - h.avg_sold_price)
		/ h.avg_sold_price * 100, 1) AS pct_diff_from_historical
FROM rets_property rp
JOIN historical_avg h ON rp.L_City = h.City
GROUP BY rp.L_City, h.avg_sold_price
HAVING pct_diff_from_historical > 30
ORDER BY pct_diff_from_historical DESC;


-- 5.2 Seasonal Trends
SELECT YEAR(CloseDate) AS sale_year,
	   MONTH(CloseDate) AS sale_month,
	   COUNT(*) AS homes_sold,
	   ROUND(AVG(ClosePrice), 0) AS avg_sold_price
FROM california_sold
WHERE CloseDate IS NOT NULL
GROUP BY YEAR(CloseDate), MONTH(CloseDate)
ORDER BY avg_sold_price DESC;
-- Based on the result, June 2026 has the highest sold price. However, the homes_sold is only 947, it could be incomplete, 
-- and thus, it should be interpreted carefully.

-- How does the average discount from list price vary by bedroom count?
SELECT 
	BedroomsTotal AS bedroom_count,
	ROUND(AVG(ListPrice), 0) AS avg_list_price,
	ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
	ROUND(AVG(ListPrice - ClosePrice), 0) AS avg_discount,
	ROUND(AVG(ListPrice - ClosePrice) / AVG(ListPrice), 1) AS avg_discount_pct
FROM california_sold
WHERE ClosePrice IS NOT NULL
  AND ListPrice > 0
  AND BedroomsTotal IS NOT NULL
GROUP BY bedroom_count
HAVING COUNT(*) >= 10
ORDER BY bedroom_count;

-- Cities where homes typically sell within 2% of asking price
SELECT 
    City,
    COUNT(*) AS homes_sold,
    ROUND(AVG(ListPrice), 0) AS avg_list_price,
    ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
    ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS avg_sale_to_list_pct,
    ROUND(AVG((ClosePrice - ListPrice) / ListPrice) * 100, 1) AS avg_pct_diff_from_list
FROM california_sold
WHERE ClosePrice IS NOT NULL
  AND ListPrice > 0
GROUP BY City
HAVING COUNT(*) >= 10
   AND ABS(AVG((ClosePrice - ListPrice) / ListPrice) * 100) <= 2
ORDER BY avg_pct_diff_from_list DESC;

-- BROKEN: Compare active prices with historical sold prices by raw city name.
-- The original query joined p.L_City directly to h.City.

-- DEBUG NOTES:
-- The guide's original query runs, but the LEFT JOIN produces NULL historical
-- values when city names differ in capitalization or surrounding spaces. I
-- diagnosed it by comparing DISTINCT city values from both tables. 
-- Fixed: LOWER(TRIM()) creates the same normalized join key on both sides.

-- FIXED:
WITH historical AS (
    SELECT
        LOWER(TRIM(City)) AS city_key,
        ROUND(AVG(ClosePrice), 0) AS avg_sold
    FROM california_sold
    WHERE ClosePrice IS NOT NULL
      AND City IS NOT NULL
    GROUP BY LOWER(TRIM(City))
)
SELECT
    p.L_City,
    ROUND(AVG(p.L_SystemPrice), 0) AS avg_active_price,
    h.avg_sold,
    ROUND(
        (AVG(p.L_SystemPrice) - h.avg_sold) / NULLIF(h.avg_sold, 0) * 100,
        1
    ) AS pct_diff_from_historical
FROM rets_property p
LEFT JOIN historical h
    ON LOWER(TRIM(p.L_City)) = h.city_key
WHERE p.L_SystemPrice IS NOT NULL
GROUP BY
    p.L_City,
    h.avg_sold
ORDER BY avg_active_price DESC;
