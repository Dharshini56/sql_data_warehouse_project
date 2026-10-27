# Data Catalog for the Gold Layer

## Overview
The Gold layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of **dimension tables** and a **fact table** (a star schema). All objects are SQL Server **views** built on top of the silver layer.

---

### 1. gold.dim_customers
- **Purpose:** Stores customer details, enriched with demographic and geographic data.
- **Sources:** `silver.crm_cust_info`, `silver.erp_cust_az12`, `silver.erp_loc_a101`
- **Columns:**

| Column Name     | Data Type    | Description |
|-----------------|--------------|-------------|
| customer_key    | BIGINT       | Surrogate key that uniquely identifies each customer record in the dimension. |
| customer_id     | INT          | Unique numeric ID assigned to each customer in the CRM system. |
| customer_number | NVARCHAR(50) | Alphanumeric customer code (e.g. `AW00011000`), used to link CRM and ERP data. |
| firstname       | NVARCHAR(50) | The customer's first name. |
| lastname        | NVARCHAR(50) | The customer's last name. |
| country         | NVARCHAR(50) | Country of residence (e.g. 'Germany', 'United States'); 'N/A' if unknown. |
| marital_status  | NVARCHAR(50) | Marital status of the customer ('Married', 'Single', 'N/A'). |
| gender          | NVARCHAR(50) | Gender of the customer ('Male', 'Female', 'N/A'). CRM is the master source; ERP is used when CRM is 'N/A'. |
| birth_date      | DATE         | Date of birth of the customer (YYYY-MM-DD). |
| create_date     | DATE         | Date the customer record was created in the CRM system. |

---

### 2. gold.dim_products
- **Purpose:** Provides information about the products and their attributes. Only the current version of each product is kept.
- **Sources:** `silver.crm_prd_info`, `silver.erp_px_cat_g1v2`
- **Columns:**

| Column Name    | Data Type    | Description |
|----------------|--------------|-------------|
| product_key    | BIGINT       | Surrogate key that uniquely identifies each product record in the dimension. |
| product_id     | INT          | Unique ID assigned to the product in the CRM system. |
| product_number | NVARCHAR(50) | Product code used to link to sales (e.g. `BK-R93R-62`). |
| product_name   | NVARCHAR(50) | Descriptive name of the product. |
| category_id    | NVARCHAR(50) | ID of the product category, used to link to the ERP category table. |
| category       | NVARCHAR(50) | Broad product classification (e.g. 'Bikes', 'Components'). |
| sub_category   | NVARCHAR(50) | More detailed product classification within the category. |
| maintenance    | NVARCHAR(50) | Whether the product requires maintenance ('Yes' / 'No'). |
| cost           | INT          | Cost or base price of the product. |
| product_line   | NVARCHAR(50) | Product line (e.g. 'Road', 'Mountain', 'Touring', 'Other Sales'). |
| start_date     | DATE         | Date the product became available. |

---

### 3. gold.fact_sales
- **Purpose:** Stores transactional sales data for analytical purposes. One row per order line.
- **Sources:** `silver.crm_sales_details`, joined to `gold.dim_products` and `gold.dim_customers`
- **Columns:**

| Column Name   | Data Type    | Description |
|---------------|--------------|-------------|
| order_number  | NVARCHAR(50) | Unique alphanumeric ID of each sales order (e.g. `SO54496`). |
| product_key   | BIGINT       | Surrogate key linking the order to `gold.dim_products`. |
| customer_key  | BIGINT       | Surrogate key linking the order to `gold.dim_customers`. |
| order_date    | DATE         | Date the order was placed. |
| shipping_date | DATE         | Date the order was shipped to the customer. |
| due_date      | DATE         | Date the order payment was due. |
| sales         | INT          | Total sales amount of the line item (quantity x price). |
| quantity      | INT          | Number of units ordered. |
| price         | INT          | Price per unit of the product for the line item. |
