# IDX SQL Portfolio
SQL analysis of 40,000+ California real estate records using MySQL and DBeaver. This portfolio documents a seven-week progression from schema exploration and data-quality checks to multi-table analysis, CTEs, and window functions.
## What I Analyzed
- Data quality across active listings, open houses, and historical sales
- Pricing and inventory trends across California cities
- Open-house activity by city and day of the week
- Historical sold prices compared with current active list prices
- Market competitiveness using joins, CTEs, and window functions
## Key Findings
- Los Angeles recorded the highest open-house activity in the exported city summary, with 288 events, followed by San Diego with 165 and San Jose with 155.
- Kensington had the highest average sale-to-list ratio in the exported comparison at 130.6%, although the finding is based on a relatively small sample of 31 sales.
- Berkeley recorded a 124.6% sale-to-list ratio across 280 sales, while Oakland averaged 112.1% across 1,011 sales, providing stronger evidence that above-asking outcomes also occurred in larger markets.
## SQL Skills Demonstrated
- Schema exploration with 'DESCRIBE' and 'INFORMATION_SCHEMA'
- Data-quality checks for NULLs, duplicates, outliers, and inconsistent values
- Filtering and sorting with 'WHERE', 'BETWEEN', 'LIKE', and 'ORDER BY'
- Aggregation with 'COUNT', 'AVG', 'GROUP BY', and 'HAVING'
- Multi-table analysis with 'INNER JOIN' and 'LEFT JOIN'
- Subqueries and common table expressions (CTEs)
- Window functions including 'RANK', 'NTILE', and running totals
- Debugging syntax errors, execution-order errors, and silent join inflation
## Environment
- MySQL 8.0
- Docker
- DBeaver
- GitHub

## How to Run
1. Start Docker Desktop.
2. Start the MySQL container:

   ```bash
   docker start idx-mysql-local
   ```

3. Open DBeaver and connect with:

   ```text
   Host: localhost
   Port: 3306
   Database: rets
   Username: root
   ```

4. Open a '.sql' file, set 'rets' as the active connection, and run a query with 'Cmd+Enter' on macOS or 'Ctrl+Enter' on Windows.

> The database files are not included in this repository.

## Repository Structure
```text
idx-sql-portfolio/
 README.md
 week0_setup.sql
 week1_schema_exploration.sql
 week2_queries.sql
 week3_queries.sql
 week4_queries.sql
 week5_queries.sql
 week6_queries.sql
 week7_final.sql
 exports/
  week3_city_pricing.csv
  week4_openhouse_by_city.csv
  week5_list_vs_sold.csv
  week6_final_summary.csv
  week7_investor_summary.csv
```

## Weekly Progression
Week | Focus |
| --- | --- |
| 0 | MySQL, Docker, and DBeaver setup |
| 1 | Schema exploration and data-quality profiling |
| 2 | SELECT, WHERE, ORDER BY, and NULL handling |
| 3 | Aggregations, GROUP BY, HAVING, and price per square foot |
| 4 | Multi-table JOINs and open-house analysis |
| 5 | Subqueries, CTEs, and active-versus-sold comparisons |
| 6 | Window functions, rankings, outliers, and market summaries |
| 7 | Portfolio audit, README presentation, and final investor summary |

## Database
- rets_property
- rets_openhouse
- california_sold
## Author
Jenny Li
