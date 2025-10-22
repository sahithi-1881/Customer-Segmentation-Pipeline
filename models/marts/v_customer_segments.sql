{{ config(materialized='view') }}

SELECT
  r.customer_id,
  r.recency_days, r.frequency, r.monetary,
  r.r_score, r.f_score, r.m_score, r.rfm_code,
  d.rfm_segment
FROM {{ ref('fct_rfm') }} r
LEFT JOIN {{ ref('dim_customer_segments') }} d USING (customer_id)
