# Data Architecture

The project follows the **Medallion Architecture** with three layers: Bronze, Silver and Gold.

```mermaid
flowchart LR
    subgraph Sources
        CRM[CRM<br/>CSV files]
        ERP[ERP<br/>CSV files]
    end

    subgraph DWH[Data Warehouse - SQL Server]
        B[(Bronze<br/>raw data)]
        S[(Silver<br/>cleaned data)]
        G[(Gold<br/>star schema views)]
    end

    subgraph Consumers
        BI[BI and reporting<br/>Power BI]
        SQL[Ad-hoc SQL analysis]
    end

    CRM --> B
    ERP --> B
    B -- clean and standardize --> S
    S -- integrate and model --> G
    G --> BI
    G --> SQL
```

| Layer  | Object type | Load method | Transformations | Data model | Audience |
|--------|-------------|-------------|-----------------|------------|----------|
| Bronze | Tables | Batch, full load (truncate and insert) | None, data stored as-is | None (as source) | Data engineers |
| Silver | Tables | Batch, full load (truncate and insert) | Cleansing, standardization, normalization, derived columns | None | Data engineers, analysts |
| Gold   | Views | No load, views read from silver | Data integration, business logic | Star schema | Analysts, BI tools |
