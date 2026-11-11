-- 02_funnel_by_traffic_source.sql
-- The same nested 2025 funnel, split by traffic source, to see which channels convert best.

WITH sessions AS (
  SELECT
    session_id,
    ANY_VALUE(traffic_source)              AS traffic_source,
    MAX(IF(event_type = 'product',  1, 0)) AS viewed_product,
    MAX(IF(event_type = 'cart',     1, 0)) AS added_to_cart,
    MAX(IF(event_type = 'purchase', 1, 0)) AS purchased
  FROM `bigquery-public-data.thelook_ecommerce.events`
  WHERE created_at >= TIMESTAMP('2025-01-01')
    AND created_at <  TIMESTAMP('2026-01-01')
  GROUP BY session_id
)

SELECT
  traffic_source,
  COUNT(*) AS total_sessions,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_of_sessions_pct,
  ROUND(100 * SAFE_DIVIDE(SUM(viewed_product * added_to_cart), SUM(viewed_product)), 1)                        AS view_to_cart_pct,
  ROUND(100 * SAFE_DIVIDE(SUM(viewed_product * added_to_cart * purchased), SUM(viewed_product * added_to_cart)), 1) AS cart_to_purchase_pct,
  ROUND(100 * SAFE_DIVIDE(SUM(viewed_product * added_to_cart * purchased), COUNT(*)), 1)                        AS session_conversion_pct
FROM sessions
GROUP BY traffic_source
ORDER BY session_conversion_pct DESC;
