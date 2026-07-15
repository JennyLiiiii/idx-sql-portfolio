-- ============================================================
-- IDX Exchange - Data Analyst Internship
-- Week 2: SELECT, WHERE, and ORDER BY
-- Tables: rets_property
-- Author: Jenny Li
-- ============================================================

-- AFFORDABILITY RECOMMENDATION
-- For a buyer's guide, use both total price and property size: first identify
-- homes below a practical budget, then compare price per square foot so a low
-- sticker price is not mistaken for good value. The queries below demonstrate
-- the filters needed to build those two views.

-- Select specific columns
SELECT L_DisplayId, L_Address, L_City, L_SystemPrice,
L_Keyword2, LM_Dec_3
FROM rets_property
LIMIT 20;

-- Filtering with WHERE
-- Properties in a specific city
SELECT L_DisplayId, L_Address, L_SystemPrice, L_Keyword2
FROM rets_property
WHERE L_City = 'Beverly Hills'
LIMIT 20;

-- 3+ bedroom homes under $700k
SELECT L_Address, L_City, L_SystemPrice, L_Keyword2
FROM rets_property
WHERE L_Keyword2 >= 3
  AND L_SystemPrice < 700000
ORDER BY L_SystemPrice ASC;

-- Properties between $400k and $600k
SELECT L_Address, L_City, L_SystemPrice, L_Keyword2
FROM rets_property
WHERE L_SystemPrice BETWEEN 400000 AND 600000
ORDER BY L_SystemPrice;

-- Cities starting with 'San'
SELECT L_Address, L_City, L_SystemPrice, L_Keyword2
FROM rets_property
WHERE L_City LIKE 'San%';

-- Handling NULL
-- Listing missing square footage
SELECT L_DisplayId, L_Address, L_City
FROM rets_property
WHERE LM_Int2_3 IS NULL;

-- Listings with square footage, largest first
SELECT L_DisplayId, L_Address, L_City, LM_Int2_3
FROM rets_property
WHERE LM_Int2_3 IS NOT NULL
ORDER BY LM_Int2_3 DESC
LIMIT 10;

-- BROKEN: Return the 10 cheapest Beverly Hills listings with a valid price.
-- SELECT L_Address, L_City, L_SystemPrice
-- FROM rets_property
-- WHERE L_City = Beverly Hills
--   AND L_SystemPrice IS NOT NULL
-- ORDER BY L_SystemPrice ASC
-- LIMIT '10';

-- DEBUG NOTES:
-- The guide's original query is intentionally incorrect: Beverly Hills is unquoted
-- and LIMIT is written as '10'. MySQL interprets an unquoted word as a column
-- name, while LIMIT expects an integer. The error messages point to those two
-- locations. 
-- Fixed: quote the city string and leave the row limit unquoted.

-- FIXED:
SELECT
    L_Address,
    L_City,
    L_SystemPrice
FROM rets_property
WHERE L_City = 'Beverly Hills'
  AND L_SystemPrice IS NOT NULL
ORDER BY L_SystemPrice ASC
LIMIT 10;
