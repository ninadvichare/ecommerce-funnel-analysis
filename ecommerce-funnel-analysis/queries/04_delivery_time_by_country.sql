-- 04_delivery_time_by_country.sql
-- Average and 90th-percentile days from order to delivery, by customer country,
-- for orders placed in 2025.

SELECT
  u.country,
  COUNT(*) AS delivered_orders,
  ROUND(AVG(TIMESTAMP_DIFF(o.delivered_at, o.created_at, HOUR)) / 24, 1) AS avg_days_to_deliver,
  ROUND(APPROX_QUANTILES(TIMESTAMP_DIFF(o.delivered_at, o.created_at, HOUR), 100)[OFFSET(90)] / 24, 1) AS p90_days_to_deliver
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
  ON o.user_id = u.id
WHERE o.delivered_at IS NOT NULL
  AND o.delivered_at >= o.created_at     -- drop any impossible timestamps
  AND o.created_at >= TIMESTAMP('2025-01-01')
  AND o.created_at <  TIMESTAMP('2026-01-01')
GROUP BY u.country
HAVING delivered_orders >= 200
ORDER BY avg_days_to_deliver DESC;
