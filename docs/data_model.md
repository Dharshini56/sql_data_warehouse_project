# Data Model: Sales Data Mart (Star Schema)

One fact table (`fact_sales`) in the centre, connected to two dimension tables.

```mermaid
erDiagram
    dim_customers ||--o{ fact_sales : "customer_key"
    dim_products  ||--o{ fact_sales : "product_key"

    dim_customers {
        bigint customer_key PK
        int customer_id
        nvarchar customer_number
        nvarchar firstname
        nvarchar lastname
        nvarchar country
        nvarchar marital_status
        nvarchar gender
        date birth_date
        date create_date
    }

    dim_products {
        bigint product_key PK
        int product_id
        nvarchar product_number
        nvarchar product_name
        nvarchar category_id
        nvarchar category
        nvarchar sub_category
        nvarchar maintenance
        int cost
        nvarchar product_line
        date start_date
    }

    fact_sales {
        nvarchar order_number
        bigint product_key FK
        bigint customer_key FK
        date order_date
        date shipping_date
        date due_date
        int sales
        int quantity
        int price
    }
```

**Business rule:** `sales = quantity x price`.

- **Dimensions** describe the business entities (who and what).
- **Fact** records the measurable events (how much and how many).
- The fact table stores **surrogate keys**, not the source IDs, so it stays independent of the source systems.
