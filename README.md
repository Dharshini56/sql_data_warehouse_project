# Data Warehouse Project (SQL Server)

A modern data warehouse built in SQL Server using the Medallion architecture
(Bronze, Silver, Gold) to consolidate sales data from CRM and ERP systems
and support analytical reporting.

![Architecture](docs/architecture.png)

## Project Requirements
**Data Engineering:** consolidate ERP and CRM CSV data, fix data quality
issues, integrate both sources into one analytical model, latest data only.
**Analytics:** SQL-based insights into customer behavior, product
performance, and sales trends.

## Tech Stack
SQL Server, SSMS, draw.io, Git/GitHub

## Architecture
| | Bronze | Silver | Gold |
|---|---|---|---|
| Purpose | Raw data as-is | Cleaned, standardized | Business-ready |
| Object type | Tables | Tables | Views |
| Load | Full load (Truncate & Insert) | Full load (Truncate & Insert) | None |
| Transformations | None | Cleansing, standardization, normalization, derived columns, enrichment | Integration, aggregation, business logic |
| Data model | None | None | Star schema |

## ETL Approach
Pull-based full extraction from CSV files, batch processing, Truncate & Insert,
SCD Type 1 (overwrite).

## Data Model (Gold)
![Star schema](docs/data_model.png)

## Repository Structure
```
datasets/   source CSV files
docs/       diagrams and documentation
scripts/    bronze, silver, gold SQL scripts
tests/      data quality checks
```

## How to Run
1. Install SQL Server and SSMS
2. Clone this repo
3. Run the database and schema creation script
4. Run the Bronze, Silver, and Gold scripts in order

## About Me
DHARSHINIDEVARAJ | https://www.linkedin.com/in/dharshini-devaraj-bb39b0249/ | dhachudharshini7010@gmail.com
