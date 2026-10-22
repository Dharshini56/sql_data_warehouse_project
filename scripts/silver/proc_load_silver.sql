/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'silver' schema from the
    'bronze' schema. It performs the ETL (Extract, Transform, Load) process
    to populate the silver tables.
 
    Actions performed:
        - Truncates the silver tables before loading data (full load).
        - Cleans and standardizes the data from the bronze tables:
            * Removes duplicates and unwanted spaces
            * Standardizes codes (gender, marital status, product line, country)
            * Handles NULLs, invalid dates and incorrect sales/price values
            * Derives new columns (cat_id, prd_end_dt)
        - Inserts the transformed data into the silver tables.
        - Prints messages, step durations and total load duration, and handles
          errors with TRY...CATCH.
 
Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.
 
Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME,
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        ------------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        -- 1. silver.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT cst_id,
               cst_key,
               TRIM(cst_firstname),
               TRIM(cst_lastname),
               CASE WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
                    WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
                    ELSE 'N/A'
               END cst_marital_status,
               CASE WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
                    WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
                    ELSE 'N/A'
               END cst_gndr,
               cst_create_date
        FROM (
            SELECT bronze.crm_cust_info.*,
                   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag = 1;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- 2. silver.crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data Into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT prd_id,
               REPLACE(TRIM(SUBSTRING(prd_key, 1, 5)), '-', '_') AS cat_id,
               TRIM(SUBSTRING(prd_key, 7, LEN(prd_key))) AS prd_key,
               TRIM(prd_nm) AS prd_nm,
               ISNULL(prd_cost, 0) AS prd_cost,
               CASE
                   WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                   WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                   WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                   WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                   ELSE 'N/A'
               END prd_line,
               prd_start_dt,
               DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- 3. silver.crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data Into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT sls_ord_num,
               sls_prd_key,
               sls_cust_id,
               CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                    ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
               END sls_order_dt,
               CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                    ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
               END sls_ship_dt,
               CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                    ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
               END sls_due_dt,
               CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
                         THEN sls_quantity * ABS(sls_price)
                    ELSE sls_sales
               END sls_sales,
               sls_quantity,
               CASE WHEN sls_price <= 0 OR sls_price IS NULL
                         THEN sls_sales / NULLIF(sls_quantity, 0)
                    ELSE sls_price
               END sls_price
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        ------------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';

        -- 4. silver.erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (CID, BDATE, GEN)
        SELECT
            CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
                 ELSE CID
            END AS CID,
            CASE WHEN BDATE > GETDATE() THEN NULL
                 ELSE BDATE
            END AS BDATE,
            CASE WHEN UPPER(GEN) IN ('F', 'FEMALE') THEN 'Female'
                 WHEN UPPER(GEN) IN ('M', 'MALE') THEN 'Male'
                 ELSE 'N/A'
            END AS GEN
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- 5. silver.erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (CID, CNTRY)
        SELECT
            REPLACE(CID, '-', '') AS CID,
            CASE WHEN CNTRY = 'DE' THEN 'Germany'
                 WHEN CNTRY IN ('US', 'USA') THEN 'United States'
                 WHEN CNTRY IS NULL OR CNTRY = ' ' THEN 'N/A'
                 ELSE TRIM(CNTRY)
            END AS CNTRY
        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- 6. silver.erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (ID, CAT, SUBCAT, MAINTENANCE)
        SELECT ID, CAT, SUBCAT, MAINTENANCE
        FROM bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        ------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';
    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
GO

EXEC silver.load_silver;
