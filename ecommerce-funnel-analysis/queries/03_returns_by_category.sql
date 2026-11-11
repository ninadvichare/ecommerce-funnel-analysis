-- 03_returns_by_category.sql
-- Return rate and returned revenue by product category, for items ordered in 2025.
-- Only items that reached the customer (Complete or Returned) are counted, so
-- cancelled and in-transit items do not dilute the return rate.

SELECT
  p.category,
  COUNT(*)                                                         AS items_delivered,
  COUNTIF(oi.status = 'Returned')                                  AS items_returned,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(oi.status = 'Returned'), COUNT(*)), 1) AS return_rate_pct,
  ROUND(SUM(IF(oi.status = 'Returned', oi.sale_price, 0)), 0)      AS returned_revenue_usd,
  ROUND(100 * SAFE_DIVIDE(SUM(IF(oi.status = 'Returned', oi.sale_price, 0)),
                          SUM(oi.sale_price)), 1)                  AS revenue_returned_pct
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
WHERE oi.status IN ('Complete', 'Returned')
  AND oi.created_at >= TIMESTAMP('2025-01-01')
  AND oi.created_at <  TIMESTAMP('2026-01-01')
GROUP BY p.category
HAVING items_delivered >= 500          -- ignore tiny categories
ORDER BY return_rate_pct DESC;
