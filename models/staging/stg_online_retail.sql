{{ config(materialized='view') }}

WITH src AS (
  SELECT * FROM {{ source('raw','CUSTOMER_INFO') }}
),
clean AS (
  SELECT
    CAST(InvoiceNo  AS VARCHAR)        AS invoice_no,
    CAST(StockCode  AS VARCHAR)        AS product_id,
    Description                         AS description,
    CAST(Quantity   AS INTEGER)        AS quantity,
    TRY_TO_TIMESTAMP_NTZ(InvoiceDate, 'MM/DD/YYYY HH24:MI')  AS order_ts,          -- safer than TO_TIMESTAMP_NTZ
    CAST(UnitPrice  AS NUMBER(12,2))   AS unit_price,
    CAST(CustomerID AS VARCHAR)        AS customer_id,
    Country                             AS country,
    (Quantity * UnitPrice)             AS line_revenue
  FROM src
  WHERE CustomerID IS NOT NULL
    AND NVL(UnitPrice,0) > 0
    AND NVL(Quantity,0) > 0
    AND (InvoiceNo IS NULL OR SUBSTR(InvoiceNo,1,1) <> 'C')
)
SELECT * FROM clean
