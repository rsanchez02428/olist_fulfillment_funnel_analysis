USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- =========================================================
-- Query 16:Why are Orders Canceled?
-- Analyze cancelation patterns by every available dimension
-- =========================================================

WITH canceled_analysis AS (
  SELECT 
    o.order_id, 
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_approved_at,
    DATEDIFF('hour', o.order_purchase_timestamp, o.order_approved_at)
    AS hours_to_approve,
    c.customer_state,
    p.payment_type,
    p.payment_installments,
    ct.product_category_name_english AS category,
    s.seller_state
  FROM RAW.ORDERS o 
  INNER JOIN RAW.CUSTOMERS c 
  ON o.customer_id = c.customer_id
  LEFT JOIN RAW.PAYMENTS p 
  ON o.order_id = p.order_id
  LEFT JOIN RAW.ORDER_ITEMS oi 
  ON o.order_id = oi.order_id
  LEFT JOIN RAW.PRODUCTS prod 
  ON oi.product_id = prod.product_id
  LEFT JOIN RAW.CATEGORY_TRANSLATION ct 
  ON prod.product_category_name = ct.product_category_name
  LEFT JOIN RAW.SELLERS s ON oi.seller_id = s.seller_id
  WHERE o.order_status = 'canceled'
  QUALIFY ROW_NUMBER() OVER(PARTITION BY o.order_id ORDER BY p.payment_value DESC) = 1
)

SELECT
-- Top categories with cancelation
  category,
  COUNT(*) AS canceled_orders,
  ROUND(AVG(hours_to_approve), 1) AS avg_hours_to_approve,
  COUNT(DISTINCT customer_state) AS states_affected
FROM canceled_analysis
WHERE category IS NOT NULL
GROUP BY category
ORDER BY canceled_orders DESC
LIMIT 15;

-- ===========================================================
-- Query 17: Cross-State Shipping Failures
-- DO ORDERS CROSSING BRAZILIAN STATE LINES PERFORM WORSE?
-- Cross-state delivery is logistically harder than same-state
-- ===========================================================

WITH order_geo AS (
  SELECT 
    o.order_id,
    o.order_status,
    c.customer_state,
    s.seller_state,
    IFF(c.customer_state = s.seller_state, 'Same State', 'Cross State') AS shipping_type,
    DATEDIFF('day', 
      o.order_purchase_timestamp, 
      o.order_delivered_customer_date
    ) AS delivery_days
  FROM RAW.ORDERS o
  INNER JOIN RAW.CUSTOMERS c ON o.customer_id = c.customer_id
  INNER JOIN RAW.ORDER_ITEMS oi ON o.order_id = oi.order_id
  INNER JOIN RAW.SELLERS s ON oi.seller_id = s.seller_id
  QUALIFY ROW_NUMBER() OVER(PARTITION BY o.order_id ORDER BY oi.order_item_id) = 1
)

SELECT 
  shipping_type,
  COUNT(*) AS orders,
  ROUND(AVG(IFF(order_status = 'delivered', delivery_days, NULL)), 1) AS avg_delivery_days,
  ROUND(SUM(IFF(order_status = 'delivered', 1, 0)) * 100.0 / COUNT(*), 2) AS delivery_rate,
  ROUND(SUM(IFF(order_status = 'canceled', 1, 0)) * 100.0 / COUNT(*), 2) AS cancellation_rate
FROM order_geo
GROUP BY shipping_type;

-- ====================================================
-- Query 18: Negative Review Diagnosis
-- WHAT PREDICTS A NEGATIVE REVIEW?
-- The strongest signal is delivery delay — quantify it
-- =====================================================

WITH order_features AS (
  SELECT 
    o.order_id,
    r.review_score,
    DATEDIFF('day',
      o.order_estimated_delivery_date,
      o.order_delivered_customer_date
    ) AS days_late, -- Negative = early
    DATEDIFF('day',
      o.order_purchase_timestamp,
      o.order_delivered_customer_date
    ) AS total_delivery_days,
    p.payment_type,
    c.customer_state
  FROM RAW.ORDERS o 
  INNER JOIN RAW.REVIEWS r
  ON o.order_id = r.order_id
  INNER JOIN RAW.CUSTOMERS c 
  ON o.customer_id = c.customer_id
  LEFT JOIN RAW.PAYMENTS p 
  ON o.order_id = p.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
  QUALIFY ROW_NUMBER() OVER(PARTITION BY o.order_id ORDER BY p.payment_value DESC) = 1
)

-- Compare features for positive (4-5 stars) vs negative (1-2) reviews
SELECT 
  CASE
    WHEN review_score >= 4 THEN 'Positive (4-5 stars)'
    WHEN review_score = 3 THEN 'Neutral (3 stars)'
    WHEN review_score <= 2 THEN 'Negative (1-2 stars)'
  END AS sentiment,
  COUNT(*) AS orders,
  ROUND(AVG(days_late), 1) AS avg_days_late,
  ROUND(AVG(total_delivery_days), 1) AS avg_total_delivery_days, 
  ROUND(MEDIAN(days_late), 1) AS median_days_late,
  ROUND(SUM(IFF(days_late > 0, 1, 0)) * 100.0 / COUNT(*), 2) AS pct_arriving_late
FROM order_features
GROUP BY sentiment
ORDER BY sentiment;