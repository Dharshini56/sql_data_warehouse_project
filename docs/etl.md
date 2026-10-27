# ETL Techniques Used

| Stage | Technique | Where it is used |
|-------|-----------|------------------|
| Extract | Pull-style batch extraction from CSV files, full extraction | Bronze load |
| Load | Batch processing, full load with `TRUNCATE` then `INSERT` | Bronze and Silver |
| Transform: cleansing | Remove duplicates (`ROW_NUMBER`), trim spaces, handle NULLs, fix invalid dates | Silver |
| Transform: standardization | Map codes to readable values (`CASE`): 'M' to 'Male', 'S' to 'Single', 'DE' to 'Germany' | Silver |
| Transform: derived columns | `cat_id` from the product key, `prd_end_dt` using `LEAD()`, recalculated sales and price | Silver |
| Transform: data type casting | Integer dates (`YYYYMMDD`) cast to `DATE` | Silver |
| Transform: integration | Join CRM and ERP, merge gender, generate surrogate keys | Gold |
| Serve | Views over silver (no data stored) | Gold |

The silver load runs in one stored procedure, `silver.load_silver`, which prints the progress, handles errors with `TRY...CATCH` and reports the duration of every step.
