/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates the views in the 'gold' schema. The gold layer holds
    the final dimension and fact tables of a star schema:

        gold.dim_customers  -> dimension (who bought)
        gold.dim_products   -> dimension (what was bought)
        gold.fact_sales     -> fact (the sales transactions)

    Each view reads from the silver layer and:
        - Joins the CRM and ERP data into one object per business entity
        - Generates surrogate keys (customer_key, product_key)
        - Integrates gender (CRM is the master, ERP is the fallback)
        - Renames columns to clear, consistent names
        - Keeps only the current version of each product

Usage:
    - Run after the silver layer is loaded (EXEC silver.load_silver).
    - Run order matters: dim_customers and dim_products first, then fact_sales.
    - Query the views directly for analytics and reporting (e.g. Power BI).
===============================================================================
*/

-- =============================================================================
-- Dimension: gold.dim_customers
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,      -- surrogate key
    ci.cst_id             AS customer_id,
    ci.cst_key            AS customer_number,
    ci.cst_firstname      AS firstname,
    ci.cst_lastname       AS lastname,
    lo.CNTRY              AS country,
    ci.cst_marital_status AS marital_status,
    CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr              -- CRM is the master for gender
         ELSE COALESCE(ca.GEN, 'N/A')                            -- fallback to ERP
    END                   AS gender,
    ca.BDATE              AS birth_date,
    ci.cst_create_date    AS create_date
FROM silver.crm_cust_info ci                                     -- ci = CRM customer info
LEFT JOIN silver.erp_cust_az12 ca                                -- ca = ERP customer (birth date, gender)
       ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_loc_a101 lo                                 -- lo = ERP location (country)
       ON ci.cst_key = lo.CID;
GO

-- =============================================================================
-- Dimension: gold.dim_products
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pi.prd_id, pi.prd_start_dt) AS product_key,   -- surrogate key
    pi.prd_id       AS product_id,
    pi.prd_key      AS product_number,
    pi.prd_nm       AS product_name,
    pi.cat_id       AS category_id,
    pc.CAT          AS category,
    pc.SUBCAT       AS sub_category,
    pc.MAINTENANCE  AS maintenance,
    pi.prd_cost     AS cost,
    pi.prd_line     AS product_line,
    pi.prd_start_dt AS start_date
FROM silver.crm_prd_info pi                                      -- pi = CRM product info
LEFT JOIN silver.erp_px_cat_g1v2 pc                              -- pc = ERP product category
       ON pi.cat_id = pc.ID
WHERE pi.prd_end_dt IS NULL;                                     -- current products only
GO

-- =============================================================================
-- Fact: gold.fact_sales
-- =============================================================================
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,                              -- surrogate key from dim_products
    cu.customer_key AS customer_key,                             -- surrogate key from dim_customers
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd                                 -- sd = CRM sales details
LEFT JOIN gold.dim_products pr                                   -- pr = product dimension
       ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu                                  -- cu = customer dimension
       ON sd.sls_cust_id = cu.customer_id;
GO
