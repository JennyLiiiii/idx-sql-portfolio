-- ============================================================
-- IDX Exchange - Data Analyst Internship
-- Week 6: Window Functions
-- Tables: rets_property, california_sold
-- Author: Jenny Li
-- ============================================================

-- MARKET OPPORTUNITY RECOMMENDATION
-- Treat cities with sale-to-list ratios above 100% and relatively constrained
-- inventory as competitive. Treat cities with ratios below 100% and active list
-- prices near or below historical sold prices as buyer opportunities. Apply a
-- minimum sample size before presenting either label so small cities and price
-- outliers do not dominate the investor summary.

-- Window Functions
SELECT City,
	ROUND(AVG(ListPrice), 0) AS avg_price,
	RANK() OVER (
		ORDER BY AVG(ListPrice) DESC
	) AS price_rank
FROM california_sold
WHERE ListPrice IS NOT NULL
GROUP BY City 
LIMIT 20;

-- Rank all cities with 10+ listings by average price using RANK()
WITH city_active_summary AS (
    SELECT
        L_City AS city,
        COUNT(DISTINCT L_DisplayId) AS active_listings,
        AVG(L_SystemPrice) AS avg_active_price
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
      AND L_City IS NOT NULL
    GROUP BY L_City
    HAVING COUNT(*) >= 10
)

SELECT
    city,
    active_listings,
    ROUND(avg_active_price, 0) AS avg_active_price,

    RANK() OVER (
        ORDER BY avg_active_price DESC
    ) AS city_price_rank

FROM city_active_summary
ORDER BY city_price_rank;

-- For each city, show only the single most expensive listing (RANK + CTE wrapper)
WITH ranked_listings AS(
	SELECT L_DisplayId, L_City, L_SystemPrice,
		   RANK() OVER (
		   		PARTITION BY L_City
		   		ORDER BY L_SystemPrice DESC) AS price_rank
	FROM rets_property rp 
	WHERE L_City IS NOT NULL 
	  AND rp.L_SystemPrice IS NOT NULL
)

SELECT L_City, L_DisplayId, L_SystemPrice
FROM ranked_listings
WHERE price_rank = 1
ORDER BY L_SystemPrice DESC;

-- Flag listings priced more than 2 standard deviations above their city mean
WITH city_stats AS (
    SELECT
        L_City,
        AVG(L_SystemPrice) AS city_avg_price,
        STDDEV_SAMP(L_SystemPrice) AS city_std_price,
        COUNT(DISTINCT L_DisplayId) AS city_listing_count
    FROM rets_property
    WHERE L_City IS NOT NULL
      AND L_SystemPrice IS NOT NULL
    GROUP BY L_City
),

flagged_listings AS (
    SELECT
        rp.L_DisplayId,
        rp.L_City,
        rp.L_SystemPrice,
        cs.city_avg_price,
        cs.city_std_price,
        cs.city_avg_price + 2 * cs.city_std_price AS high_price_threshold,
        cs.city_listing_count,

        CASE
            WHEN rp.L_SystemPrice > cs.city_avg_price + 2 * cs.city_std_price
            THEN 1
            ELSE 0
        END AS is_more_than_2sd_above_mean

    FROM rets_property rp
    INNER JOIN city_stats cs
        ON rp.L_City = cs.L_City
    WHERE rp.L_City IS NOT NULL
      AND rp.L_SystemPrice IS NOT NULL
)

SELECT
    L_DisplayId,
    L_City,
    L_SystemPrice,
    ROUND(city_avg_price, 0) AS city_avg_price,
    ROUND(city_std_price, 0) AS city_std_price,
    ROUND(high_price_threshold, 0) AS high_price_threshold,
    city_listing_count
FROM flagged_listings
WHERE is_more_than_2sd_above_mean = 1
   AND city_listing_count >= 10
ORDER BY L_City, L_SystemPrice DESC;

-- Which cities have the most consistent pricing? (lowest std deviation relative to mean)
WITH listing_base AS (
    SELECT DISTINCT
        L_DisplayId,
        L_City,
        L_SystemPrice
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
      AND L_SystemPrice > 0
      AND L_City IS NOT NULL
),

city_stats AS (
    SELECT DISTINCT
        L_City,
        COUNT(*) OVER (PARTITION BY L_City) AS listing_count,
        AVG(L_SystemPrice) OVER (PARTITION BY L_City) AS city_avg_price,
        STDDEV_SAMP(L_SystemPrice) OVER (PARTITION BY L_City) AS city_std_price,
        STDDEV_SAMP(L_SystemPrice) OVER (PARTITION BY L_City)
            / AVG(L_SystemPrice) OVER (PARTITION BY L_City) AS relative_std
    FROM listing_base
)

SELECT
    L_City,
    listing_count,
    ROUND(city_avg_price, 0) AS city_avg_price,
    ROUND(city_std_price, 2) AS city_std_price,
    ROUND(relative_std, 4) AS relative_std
FROM city_stats
WHERE listing_count >= 5
ORDER BY relative_std ASC
LIMIT 10;

-- Final summary table: city, active listings, avg active price, avg historical sold, ratio
WITH active_base AS (
	SELECT DISTINCT L_DisplayId, TRIM(L_City) AS city, L_SystemPrice
	FROM rets_property rp
	WHERE rp.L_City IS NOT NULL
	  AND rp.L_SystemPrice IS NOT NULL
	  AND rp.L_SystemPrice > 0),

active_city AS (
 	SELECT DISTINCT city, COUNT(*) OVER (PARTITION BY city) AS active_listings,
 		AVG(L_SystemPrice) OVER (PARTITION BY city) AS avg_active_price
 	FROM active_base
),

sold_base AS (
    SELECT
        TRIM(City) AS city,
        ClosePrice
    FROM california_sold
    WHERE City IS NOT NULL
        AND ClosePrice IS NOT NULL
        AND ClosePrice > 0
),

sold_city AS (
    SELECT DISTINCT
        city,
        AVG(ClosePrice) OVER (PARTITION BY city) AS avg_historical_sold
    FROM sold_base
)

SELECT
    a.city,
    a.active_listings,
    ROUND(a.avg_active_price, 0) AS avg_active_price,
    ROUND(s.avg_historical_sold, 0) AS avg_historical_sold,
    ROUND(a.avg_active_price / NULLIF(s.avg_historical_sold, 0), 2) AS ratio
FROM active_city a
JOIN sold_city s
    ON LOWER(a.city) = LOWER(s.city)
ORDER BY ratio DESC;

-- BROKEN: Filter rank_in_city in the same query's WHERE clause.
-- The original query used: AND rank_in_city = 1.

-- DEBUG NOTES:
-- The guide's original query filters rank_in_city in WHERE and MySQL reports
-- "Unknown column rank_in_city" because WHERE runs before the window function
-- creates that alias. I used the execution order to diagnose the error. 
-- Fixed: calculate the rank in a CTE, then filter it in the outer query.

-- FIXED:
WITH ranked AS (
	SELECT
	       L_DisplayId,
	       L_Address,
	       L_City,
	       L_SystemPrice,
		   RANK() OVER (
		    PARTITION BY L_City ORDER BY L_SystemPrice DESC
		   ) AS rank_in_city
	FROM rets_property
	WHERE L_SystemPrice IS NOT NULL
	  AND L_City IS NOT NULL
)

SELECT
    L_DisplayId,
    L_Address,
    L_City,
    L_SystemPrice,
    rank_in_city
FROM ranked
WHERE rank_in_city = 1
ORDER BY L_City;

-- Exercise 6.1
SELECT L_DisplayId, L_Address, L_City, L_SystemPrice,
	   ROUND(AVG(L_SystemPrice) OVER (PARTITION BY L_City), 0) AS city_avg_price,
	   ROUND(L_SystemPrice - AVG(L_SystemPrice) OVER
	   	(PARTITION BY L_City), 0) AS diff_from_city_avg,
	   RANK() OVER (
	   	PARTITION BY L_City ORDER BY L_SystemPrice DESC
	   ) AS rank_in_city
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
  AND L_City IS NOT NULL
ORDER BY L_City, rank_in_city LIMIT 30;

-- Exercise 6.2
WITH city_stats AS (
	SELECT City,
		AVG(ListPrice) AS city_avg,
		STDDEV(ListPrice) AS city_stddev
	FROM california_sold cs 
	WHERE ListPrice IS NOT NULL
	GROUP BY City HAVING COUNT(*) >= 5
)
SELECT p.L_DisplayId, p.L_Address, p.L_City, p.L_SystemPrice,
	   ROUND(cs.city_avg, 0) AS city_avg_price,
	   ROUND(p.L_SystemPrice / cs.city_avg * 100, 1) AS pct_of_city_avg
FROM rets_property p
JOIN city_stats cs ON p.L_City = cs.City
WHERE p.L_SystemPrice > cs.city_avg * 1.5
ORDER BY pct_of_city_avg DESC LIMIT 20;

-- Exercise 6.3
WITH quartiles AS (
	SELECT ClosePrice, City,
		NTILE(4) OVER (ORDER BY ClosePrice) AS price_quartile
	FROM california_sold WHERE ClosePrice IS NOT NULL
)
SELECT price_quartile,
	   COUNT(*) AS num_sold,
	   ROUND(MIN(ClosePrice), 0) AS min_price,
	   ROUND(MAX(ClosePrice), 0) AS max_price,
	   ROUND(AVG(ClosePrice), 0) AS avg_price
FROM quartiles
GROUP BY price_quartile ORDER BY price_quartile;

-- Exercise 6.4
WITH monthly AS (
	SELECT DATE_FORMAT(ListingContractDate, '%Y-%m') AS list_month,
		COUNT(*) AS new_listings
	FROM rets_property WHERE ListingContractDate IS NOT NULL
	GROUP BY DATE_FORMAT(ListingContractDate, '%Y-%m')
)
SELECT list_month, new_listings,
	SUM(new_listings) OVER (
		ORDER BY list_month ROWS UNBOUNDED PRECEDING
	) AS running_total
FROM monthly ORDER BY list_month;
