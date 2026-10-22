/*
===============================================================================
Quality Checks: Silver Layer
===============================================================================
Script Purpose:
    This script runs data quality checks on the 'silver' schema after
    silver.load_silver has been executed. It checks for:
        - NULLs or duplicates in primary keys
        - Unwanted spaces in text fields
        - Data standardization and consistency
        - Invalid date ranges and date orders
        - Data consistency between related fields (sales = quantity * price)

Usage Notes:
    - Run this after: EXEC silver.load_silver;
    - Every check should return NO ROWS unless the comment says otherwise.
      For the "distinct values" checks, read the list and confirm that only
      the expected standardized values appear.
===============================================================================
*/

-- ============================================================
-- silver.crm_cust_info
-- ============================================================

-- Check for NULLs or duplicates in the primary key
-- Expectation: No results
SELECT cst_id, COUNT(*) AS cnt
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data standardization: check the distinct values
-- Expectation: Married, Single, N/A  and  Male, Female, N/A
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;


-- ============================================================
-- silver.crm_prd_info
-- ============================================================

-- Check for NULLs or duplicates in the primary key
-- Expectation: No results
SELECT prd_id, COUNT(*) AS cnt
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or negative costs
-- Expectation: No results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardization: check the distinct values
-- Expectation: Mountain, Road, Touring, Other Sales, N/A
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- Check for invalid date orders (end date before start date)
-- Expectation: No results
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ============================================================
-- silver.crm_sales_details
-- ============================================================

-- Check for invalid date orders
-- Expectation: No results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Check data consistency: sales = quantity * price, and no NULL/zero/negative values
-- Expectation: No results
SELECT DISTINCT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- Check that every sales row has a matching product and customer
-- (Referential integrity, informational: review any rows returned)
SELECT DISTINCT sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT DISTINCT sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);


-- ============================================================
-- silver.erp_cust_az12
-- ============================================================

-- Check for birth dates in the future
-- Expectation: No results
SELECT BDATE
FROM silver.erp_cust_az12
WHERE BDATE > GETDATE();

-- Check for very old birth dates
-- (Informational: review any rows returned, these are not changed in Silver)
SELECT BDATE
FROM silver.erp_cust_az12
WHERE BDATE < '1924-01-01';

-- Data standardization: check the distinct values
-- Expectation: Male, Female, N/A
SELECT DISTINCT GEN FROM silver.erp_cust_az12;


-- ============================================================
-- silver.erp_loc_a101
-- ============================================================

-- Data standardization: check the distinct country values
-- Expectation: full country names (Germany, United States, ...) and N/A
SELECT DISTINCT CNTRY
FROM silver.erp_loc_a101
ORDER BY CNTRY;

-- Check that the customer IDs match the CRM customer keys
-- (Informational: review any rows returned)
SELECT CID
FROM silver.erp_loc_a101
WHERE CID NOT IN (SELECT cst_key FROM silver.crm_cust_info);


-- ============================================================
-- silver.erp_px_cat_g1v2
-- ============================================================

-- Check for unwanted spaces
-- Expectation: No results
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE CAT != TRIM(CAT)
   OR SUBCAT != TRIM(SUBCAT)
   OR MAINTENANCE != TRIM(MAINTENANCE);

-- Data standardization: check the distinct values
SELECT DISTINCT CAT FROM silver.erp_px_cat_g1v2;
SELECT DISTINCT SUBCAT FROM silver.erp_px_cat_g1v2;
SELECT DISTINCT MAINTENANCE FROM silver.erp_px_cat_g1v2;

-- Check that every product category in CRM exists in the ERP category table
-- (Informational: review any rows returned)
SELECT DISTINCT cat_id
FROM silver.crm_prd_info
WHERE cat_id NOT IN (SELECT ID FROM silver.erp_px_cat_g1v2);
