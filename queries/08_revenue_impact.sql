USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ==========================================================================
-- Query 15: Dollar Impact of Each Funnel Improvment
-- IF WE FIX EACH STAGE BY 1 PERCENTAGE POINT, HOW MUCH REVENUE IS RECOVERED?
-- ==========================================================================
WITH funnel_with_revenue AS (
  SELECT
    COUNT(*) AS total_orders,

    SUM(IFF(o.order_approved_at IS NOT NULL, 1, 0)) AS approved, 
    SUM(IFF(o.order_delivered_carrier_date IS NOT NULL, 1, 0)) AS
    shipped, 
    SUM(IFF(o.order_delivered_customer_date IS NOT NULL, 1, 0)) AS 
    delivered,

    -- Average revenue per delivered order
    ROUND(AVG(IFF(
      o.order_status = 'delivered',
      order_total, 
      NULL
    )), 2) AS avg_order_value

  FROM RAW.ORDERS o
  INNER JOIN (
    SELECT order_id, SUM(price + freight_value) AS order_total
    FROM RAW.ORDER_ITEMS
    GROUP BY order_id
  ) totals ON o.order_id = totals.order_id
)

SELECT
  'created_to_approved' AS funnel_step,
  total_orders AS users_at_step,
  ROUND(approved * 100 / total_orders, 2) AS current_rate_pct,
  ROUND(0.01 * total_orders * 
    (delivered * 1.0 / approved) * 
    avg_order_value, 2
  ) AS additional_revenue_per_1pp_improvement
FROM funnel_with_revenue

UNION ALL

SELECT 
  'approved_to_shipped',
  approved,
  ROUND(shipped * 100.0 / approved, 2),
  ROUND(0.01 * approved * 
    (delivered * 1.0 / shipped) *
    avg_order_value, 2)
FROM funnel_with_revenue

UNION ALL

SELECT 
  'shipped_to_delivered',
  shipped,
  ROUND(delivered * 100.0 / shipped, 2),
  ROUND(0.01 * shipped * avg_order_value, 2)
FROM funnel_with_revenue

ORDER BY additional_revenue_per_1pp_improvement DESC;