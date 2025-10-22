
{{ config(materialized='view') }}

WITH base AS (
  SELECT * FROM {{ ref('fct_rfm') }}
)
SELECT
  customer_id, recency_days, frequency, monetary,
  r_score, f_score, m_score, rfm_code,
  CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 4 AND f_score >= 3                 THEN 'Loyal'
    WHEN r_score >= 3 AND m_score >= 4                 THEN 'Big Spenders'
    WHEN r_score <= 2 AND f_score <= 2                 THEN 'At Risk'
    WHEN r_score = 1  AND f_score = 1                  THEN 'Churned'
    ELSE 'Potential'
  END AS rfm_segment
FROM base
