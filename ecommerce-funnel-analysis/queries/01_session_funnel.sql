-- 01_session_funnel.sql
-- Session-level funnel for calendar year 2025: product view -> add to cart -> purchase.
-- Each step counts only sessions that also completed the step before it,
-- so the funnel is strictly nested and the percentages are true step conversions.
-- Dates are pinned because thelook_ecommerce is refreshed daily; a fixed window
-- keeps the numbers in the README reproducible.

WITH sessions AS (
  SELECT
    session_id,
    MAX(IF(event_type = 'product',  1, 0)) AS viewed_product,
    MAX(IF(event_type = 'cart',     1, 0)) AS added_to_cart,
    MAX(IF(event_type = 'purchase', 1, 0)) AS purchased
  FROM `bigquery-public-data.thelook_ecommerce.events`
  WHERE created_at >= TIMESTAMP('2025-01-01')
    AND created_at <  TIMESTAMP('2026-01-01')
  GROUP BY session_id
),

funnel AS (
  SELECT
    COUNT(*)                                        AS total_sessions,
    SUM(viewed_product)                             AS step1_viewed_product,
    SUM(viewed_product * added_to_cart)             AS step2_added_to_cart,
    SUM(viewed_product * added_to_cart * purchased) AS step3_purchased,
    SUM(purchased)                                  AS all_purchasing_sessions
  FROM sessions
)

SELECT
  total_sessions,
  step1_viewed_product,
  step2_added_to_cart,
  step3_purchased,
  ROUND(100 * SAFE_DIVIDE(step2_added_to_cart, step1_viewed_product), 1) AS view_to_cart_pct,
  ROUND(100 * SAFE_DIVIDE(step3_purchased, step2_added_to_cart), 1)      AS cart_to_purchase_pct,
  ROUND(100 * SAFE_DIVIDE(step3_purchased, total_sessions), 1)           AS session_conversion_pct,
  -- Data quality check: purchases that skipped a funnel step. Should be 0 or close to it.
  all_purchasing_sessions - step3_purchased                               AS purchases_outside_funnel
FROM funnel;
