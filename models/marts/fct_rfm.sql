{{ config(materialized='table') }}

WITH maxdate AS (
  -- anchor recency to the data's own last order date
  SELECT COALESCE(MAX(CAST(order_ts AS DATE)), CURRENT_DATE()) AS as_of_date
  FROM {{ ref('stg_online_retail') }}
),
orders AS (
  SELECT
    s.customer_id,
    DATE_TRUNC('month', s.order_ts)          AS order_month,
    COUNT(DISTINCT s.invoice_no)             AS orders,
    SUM(s.line_revenue)                      AS revenue,
    MIN(CAST(s.order_ts AS DATE))            AS first_purchase,
    MAX(CAST(s.order_ts AS DATE))            AS last_purchase
  FROM {{ ref('stg_online_retail') }} s
  WHERE s.order_ts IS NOT NULL
  GROUP BY 1,2
),
cust AS (
  SELECT
    o.customer_id,
    MAX(o.last_purchase)                                       AS last_purchase,
    DATEDIFF('day', MAX(o.last_purchase), (SELECT as_of_date FROM maxdate))
      AS recency_days,
    SUM(o.orders)                                              AS frequency,
    SUM(o.revenue)                                             AS monetary
  FROM orders o
  GROUP BY 1
),
scored AS (
  SELECT
    customer_id, recency_days, frequency, monetary,
    NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_ntile_asc,   -- more recent = better
    NTILE(5) OVER (ORDER BY frequency DESC)    AS f_ntile_desc,
    NTILE(5) OVER (ORDER BY monetary  DESC)    AS m_ntile_desc
  FROM cust
)
SELECT
  customer_id,
  recency_days,
  frequency,
  monetary,
  6 - r_ntile_asc       AS r_score,
  6 - f_ntile_desc      AS f_score,
  6 - m_ntile_desc      AS m_score,
  ((6 - r_ntile_asc) * 100) + ((6 - f_ntile_desc) * 10) + (6 - m_ntile_desc) AS rfm_code
FROM scored
