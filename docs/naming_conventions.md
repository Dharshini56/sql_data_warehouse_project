# Naming Conventions

This document describes the naming rules used for schemas, tables, views, columns and other objects.

## General Principles
- **Style:** `snake_case` (lowercase words separated by underscores).
- **Language:** English.
- **Reserved words:** do not use SQL reserved words as object names.

## Table Naming Conventions

### Bronze and Silver rules
- All names start with the **source system name**, followed by the entity name, exactly as in the source.
- Pattern: `<sourcesystem>_<entity>`
  - `crm_cust_info`: customer information from the CRM system.
  - `erp_loc_a101`: location data from the ERP system.

### Gold rules
- All names use a category prefix followed by a meaningful business name.
- Pattern: `<category>_<entity>`
  - `dim_customers`: dimension table for customer data.
  - `dim_products`: dimension table for product data.
  - `fact_sales`: fact table holding sales transactions.

| Prefix | Meaning          | Example         |
|--------|------------------|-----------------|
| `dim_` | Dimension table  | `dim_products`  |
| `fact_`| Fact table       | `fact_sales`    |

## Column Naming Conventions

### Surrogate keys
- Surrogate key columns end with `_key`.
- Pattern: `<entity>_key`
  - `customer_key`: surrogate key in `dim_customers`.
  - `product_key`: surrogate key in `dim_products`.

### Technical columns
- Metadata columns added by the warehouse start with `dwh_`.
- Pattern: `dwh_<column_name>`
  - `dwh_create_date`: date and time the row was loaded into the warehouse.

## Stored Procedure Naming
- Load procedures follow the pattern `<layer>.load_<layer>`.
  - `silver.load_silver`: loads the silver layer from bronze.

## Schemas
| Schema   | Purpose |
|----------|---------|
| `bronze` | Raw data, loaded as-is from the source files |
| `silver` | Cleaned and standardized data |
| `gold`   | Business-ready star schema (views) |

## File Naming (scripts)
| Pattern            | Example                 |
|--------------------|-------------------------|
| `ddl_<layer>.sql`  | `ddl_silver.sql`        |
| `proc_load_<layer>.sql` | `proc_load_silver.sql` |
| `quality_checks_<layer>.sql` | `quality_checks_gold.sql` |
