USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS; 
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ============================================
-- Query 13: Day-of-Week Analysis
-- DOES ORDER PERFORMANCE VARY BY DAY OF WEEK?
-- ============================================
SELECT
    DAYNAME(order_purchase_timestamp) AS day_of_week, 
    DAYOFWEEK(order_purchase_timestamp) AS day_num, 
    COUNT(*) AS orders, 
    ROUND(SUM(IFF(order_status= 'delivered', 1, 0)) * 100 / COUNT(*),
        2) AS delivery_rate,
    ROUND(AVG(IFF(
        order_status = 'delivered',
        DATEDIFF('day', order_purchase_timestamp, 
        order_delivered_customer_date),
        NULL
    )), 1) AS avg_delivery_days
FROM RAW.ORDERS
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY day_of_week, day_num
ORDER BY day_num;

-- =========================================
-- Query 14: Monthly Trends
-- MONTHLY ORDER VOLUME AND DELIVERY METRICS
-- =========================================
WITH monthly_stats AS (
  SELECT 
    DATE_TRUNC('MONTH', order_purchase_timestamp)::DATE AS month,
    COUNT(*) AS orders,
    ROUND(SUM(IFF(order_status = 'delivered', 1, 0)) * 100.0 / COUNT(*), 2) AS delivery_rate,
    ROUND(SUM(IFF(order_status = 'canceled', 1, 0)) * 100.0 / COUNT(*), 2) AS cancellation_rate
  FROM RAW.ORDERS
  WHERE order_purchase_timestamp IS NOT NULL
  GROUP BY month
)
SELECT
  month,
  orders,
  delivery_rate,
  cancellation_rate,
  ROUND(
    (orders - LAG(orders) OVER (ORDER BY month)) * 100.0 /
    NULLIF(LAG(orders) OVER (ORDER BY month), 0),
    2
  ) AS mom_growth_pct
FROM monthly_stats
ORDER BY month;

