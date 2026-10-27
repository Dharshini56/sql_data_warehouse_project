/*
===============================================================================
Quality Checks: Gold Layer
===============================================================================
Script Purpose:
    This script runs data quality checks on the 'gold' views to validate
    the integrity and accuracy of the star schema. It checks:
        - Uniqueness of the surrogate keys in the dimensions
        - No duplicates created by the joins
        - Data integration (gender merged from CRM and ERP)
        - Referential integrity between the fact table and the dimensions
        - Data consistency in the fact table (sales, quantity, price, dates)

Usage Notes:
    - Run this after creating the gold views (ddl_gold.sql).
    - Every check should return NO ROWS unless the comment says otherwise.
      For the "distinct values" and "informational" checks, read the result
      and confirm it looks right.
===============================================================================
*/

-- ============================================================
-- gold.dim_customers
-- ============================================================

-- Check that the surrogate key is unique
-- Expectation: No results
SELECT customer_key, COUNT(*) AS cnt
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check that the joins did not create duplicate customers
-- Expectation: No results
SELECT customer_id, COUNT(*) AS cnt
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Data integration: check the gender values after merging CRM and ERP
-- Expectation: Male, Female, N/A
SELECT DISTINCT gender
FROM gold.dim_customers;

-- Data integration: compare the CRM gender with the ERP gender
-- (Informational: CRM is the master. Review rows where the two sources
--  disagree, and confirm the final 'gender' column follows the CRM value.)
SELECT DISTINCT
    ci.cst_gndr AS crm_gender,
    ca.GEN      AS erp_gender,
    cu.gender   AS final_gender
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
       ON ci.cst_key = ca.CID
LEFT JOIN gold.dim_customers cu
       ON ci.cst_id = cu.customer_id
ORDER BY crm_gender, erp_gender;

-- Check for customers without a country
-- (Informational: review any rows returned)
SELECT customer_id, customer_number, country
FROM gold.dim_customers
WHERE country IS NULL OR country = 'N/A';


-- ============================================================
-- gold.dim_products
-- ============================================================

-- Check that the surrogate key is unique
-- Expectation: No results
SELECT product_key, COUNT(*) AS cnt
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check that each product appears only once
-- (The view keeps current products only, so each product number should be unique.)
-- Expectation: No results
SELECT product_number, COUNT(*) AS cnt
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;

-- Check for products without a matching category
-- (Informational: review any rows returned. These are products whose category
--  ID is missing in the ERP category table.)
SELECT product_id, product_number, product_name, category_id
FROM gold.dim_products
WHERE category IS NULL;


-- ============================================================
-- gold.fact_sales
-- ============================================================

-- Check referential integrity: every sales row must match a product and a customer
-- Expectation: No results
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
       ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
       ON p.product_key = f.product_key
WHERE p.product_key IS NULL
   OR c.customer_key IS NULL;

-- Check that the fact table did not lose or gain rows compared with silver
-- Expectation: the two counts are equal
SELECT
    (SELECT COUNT(*) FROM silver.crm_sales_details) AS silver_rows,
    (SELECT COUNT(*) FROM gold.fact_sales)          AS gold_rows;

-- Check data consistency: sales = quantity * price, and no NULL/zero/negative values
-- Expectation: No results
SELECT DISTINCT sales, quantity, price
FROM gold.fact_sales
WHERE sales != quantity * price
   OR sales IS NULL OR quantity IS NULL OR price IS NULL
   OR sales <= 0 OR quantity <= 0 OR price <= 0
ORDER BY sales, quantity, price;

-- Check for invalid date orders
-- Expectation: No results
SELECT *
FROM gold.fact_sales
WHERE order_date > shipping_date
   OR order_date > due_date;
