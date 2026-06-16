-- ============================================================
-- IDX Exchange - Internship
-- Week 3: queries
-- Tables: rets_property, rets_openhouse, california_sold
-- Author: Jenny
-- ============================================================

-- Group by L_City
SELECT L_City,
       COUNT(*) AS total_listings,
       ROUND(AVG(L_SystemPrice), 0) AS avg_list_price,
       MIN(L_SystemPrice) AS min_price,
       MAX(L_SystemPrice) AS max_price
FROM rets_property rp 
WHERE rp.L_SystemPrice IS NOT NULL
GROUP BY L_City 
ORDER BY avg_list_price DESC;

-- Price Per Square Foot
SELECT L_City,
       COUNT(*) AS listings,
       ROUND(AVG(L_SystemPrice), 0) AS avg_price,
       ROUND(AVG(LM_Int2_3), 0) AS avg_sqft,
       ROUND(AVG(L_SystemPrice / LM_Int2_3), 2) AS avg_price_per_sqft
FROM rets_property rp 
WHERE rp.L_SystemPrice IS NOT NULL
  AND rp.LM_Int2_3 > 0
GROUP BY L_City
ORDER BY avg_price_per_sqft DESC;

-- HAVING
SELECT L_City,
       COUNT(*) AS total_listings,
       ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) > 10
ORDER BY avg_price DESC;

-- Inventory by Bedroom Count
SELECT L_Keyword2 AS bedrooms,
	   COUNT(*) AS total_listings,
	   ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property rp 
WHERE rp.L_Keyword2 IS NOT NULL
  AND rp.L_Keyword2 BETWEEN 1 AND 8
GROUP BY L_Keyword2
ORDER BY L_Keyword2;

-- BROKEN: Cities with average price above $600k (min 5 listings)
SELECT L_City,
	   COUNT(*) AS total_listings,
	   ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE AVG(L_SystemPrice) > 600000 -- Bug: wrong clause for aggregate filter
AND L_SystemPrice IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) >= 5
ORDER BY avg_price DESC;

-- Debug
SELECT L_City,
	   COUNT(*) AS total_listings,
	   ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_City 
HAVING AVG(L_SystemPrice) > 600000
   AND COUNT(*) >= 5
ORDER BY avg_price DESC;