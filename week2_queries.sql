-- ============================================================
-- IDX Exchange - Internship
-- Week 2: queries
-- Tables: rets_property, rets_openhouse, california_sold
-- Author: Jenny
-- ============================================================

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

-- BROKEN: 10 cheapest listings in Portland with a valid price
SELECT L_Address, L_City, L_SystemPrice
FROM rets_property
WHERE L_City = Portland -- Bug 1
AND L_SystemPrice IS NOT NULL
ORDER BY L_SystemPrice ASC
LIMIT '10'; -- Bug 2

-- Debug
SELECT L_Address, L_City, L_SystemPrice
FROM rets_property
WHERE L_City = 'Beverly Hills'
AND L_SystemPrice IS NOT NULL
ORDER BY L_SystemPrice ASC
LIMIT 10;