-- ============================================================
-- IDX Exchange - Data Analyst Internship
-- Week 1: Schema Exploration
-- Tables: rets_property, rets_openhouse, california_sold
-- Author: Jenny Li
-- ============================================================

-- DATA QUALITY RECOMMENDATION
-- The listing ID is unique in rets_property, but analysts should filter NULL
-- prices and square footage before pricing analysis. Open-house records have a
-- valid one-to-many relationship with listings, so joins must be deduplicated
-- before calculating listing-level averages. Historical sold data also contains
-- implausible future CloseDate values and inconsistent city coverage; validate
-- dates and normalize city names before comparing active and sold properties.

-- List all tables
SHOW TABLES;

-- More details
SELECT TABLE_NAME,
	   TABLE_ROWS,
	   ROUND(DATA_LENGTH / 1024 / 1024, 2) AS size_mb
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'rets'
ORDER BY TABLE_ROWS DESC;

-- Quick column interview
DESCRIBE rets_property;

-- Full detail via information_schema
SELECT column_name,
       data_type,
       is_nullable,
       CHARACTER_MAXIMUM_LENGTH
from information_schema.COLUMNS
where TABLE_SCHEMA = 'rets'
	and TABLE_NAME = 'rets_property'
order by ORDINAL_POSITION;

-- NULL rate check across key columns
SELECT
	COUNT(*) AS total_rows,
	SUM(CASE WHEN L_SystemPrice IS NULL THEN 1 ELSE 0 END) AS price_nulls,
	SUM(CASE WHEN L_Keyword2 IS NULL THEN 1 ELSE 0 END) AS beds_nulls,
	SUM(CASE WHEN LM_Int2_3 IS NULL THEN 1 ELSE 0 END) AS sqft_nulls,	
	SUM(CASE WHEN L_City IS NULL THEN 1 ELSE 0 END) AS city_nulls
FROM rets_property;

-- Distribution check: what values does L_Status actually contain?
SELECT L_Status,
	COUNT(*) AS total
FROM rets_property
GROUP BY L_Status
ORDER BY total DESC;

-- Sanity check: are numeric columns within realistic ranges?
SELECT
	MIN(L_SystemPrice) AS min_price, MAX(L_SystemPrice) AS max_price,
	MIN(L_Keyword2) AS min_beds, MAX(L_Keyword2) AS max_beds,
	MIN(LM_Int2_3) AS min_sqft, MAX(LM_Int2_3) AS max_sqft
FROM rets_property
WHERE L_SystemPrice IS NOT NULL;

-- Quick summary: total rows vs distinct L_DisplayIds
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT L_DisplayId) AS distinct_ids,
	COUNT(*) - COUNT(DISTINCT L_DisplayId) AS duplicates
FROM rets_property;

-- Detail: which L_DisplayIds appear more than once?
SELECT L_DisplayId, COUNT(*) AS occurrences
FROM rets_property
GROUP BY L_DisplayId
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;
-- Result:
-- No duplicate L_DisplayId values found in rets_property.

-- How many open house rows exist per listing? (expect one-to-many)
SELECT
	COUNT(DISTINCT L_DisplayId) AS distinct_listings,
	COUNT(*) AS total_rows,
	ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT L_DisplayId), 1) AS avg_rows_per_listing
FROM rets_openhouse;

-- How many rets_property listings have NO match in rets_openhouse?
SELECT COUNT(*) AS listings_without_openhouse
FROM rets_property rp
WHERE NOT EXISTS (
SELECT 1 FROM rets_openhouse ro WHERE ro.L_DisplayId = rp.L_DisplayId
);

-- Quick check column overview of california_sold
DESCRIBE california_sold;

SELECT City
FROM california_sold;

-- Null rate check for california_sold
SELECT 
	COUNT(*) AS total_rows,
	SUM(CASE WHEN ClosePrice IS NULL THEN 1 ELSE 0 END) AS closeprice_nulls
FROM california_sold cs;
-- Result:
-- No nulls in ClosePrice

-- Date range
SELECT
	MIN(CloseDate) AS earliest_date,
	MAX(CloseDate) AS Latest_date
From california_sold cs;
-- Result:
-- From 2025.12.03 to 2072.06.29

SELECT CloseDate
FROM california_sold
ORDER BY CloseDate DESC
LIMIT 20;
-- Weird dates such as 2028-06-30; 2030-09-09; 2030-12-30; 2072-06-29.

SELECT CloseDate, ClosePrice, City
FROM california_sold
ORDER BY CloseDate
LIMIT 20;

-- Do city names match between the two tables?
-- Cities in california_sold but NOT in rets_property
SELECT DISTINCT City
FROM california_sold
WHERE City NOT IN (
	SELECT DISTINCT L_City 
	FROM rets_property
	WHERE L_City IS NOT NULL
)
ORDER BY City
LIMIT 20;

SELECT COUNT(DISTINCT City) AS sold_cities_not_in_property
FROM california_sold
WHERE City NOT IN (
    SELECT DISTINCT L_City
    FROM rets_property
    WHERE L_City IS NOT NULL
);
-- There are 100 mismatches

-- BROKEN: Count listings with a missing price.
-- SELECT COUNT(*) AS missing_prices
-- FROM rets_property
-- WHERE L_SystemPrice = NULL;

-- DEBUG NOTES:
-- It returns no matches because NULL means "unknown," so an equality comparison
-- is never TRUE. I diagnosed it by checking MySQL's NULL comparison rules.
-- Fixed: use IS NULL, which is the SQL predicate designed to test missing values.

-- FIXED:
SELECT
    COUNT(*) AS missing_prices
FROM rets_property
WHERE L_SystemPrice IS NULL;
