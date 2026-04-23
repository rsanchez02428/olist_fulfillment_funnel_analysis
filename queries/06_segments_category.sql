USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ====================================================
-- Query 11: Funnel by Product Category
-- WHICH PRODUCT CATEGORIES HAVE THE WORST FULFILLMENT?
-- ====================================================

WITH order_category AS (
    -- Get the primary category per order
    SELECT 
        o.order_id,
        o.order_status, 
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        ct.product_category_name_english AS category
    FROM RAW.ORDERS o 
    INNER JOIN RAW.ORDER_ITEMS oi 
    ON o.order_id = oi.order_id
    INNER JOIN RAW.PRODUCTS p 
    ON oi.product_id = p.product_id
    LEFT JOIN RAW.CATEGORY_TRANSLATION ct 
    ON p.product_category_name = ct.product_category_name
    QUALIFY ROW_NUMBER() OVER(
        PARTITION BY o.order_id
        ORDER BY oi.order_item_id
    ) = 1 -- One row per order, using first item  
)
SELECT
    category, 
    COUNT(*) AS orders, 
    
    ROUND(SUM(IFF(order_status= 'delivered', 1, 0)) * 100.0 / COUNT(*), 2) 
        AS delivery_rate,
        
    ROUND(SUM(IFF(order_status= 'canceled', 1, 0)) * 100.0 / COUNT(*), 2)
        AS cancellation_rate,
    
    ROUND(
        SUM(IFF(order_delivered_customer_date <= order_estimated_delivery_date, 1, 
        0)) * 100.0 / NULLIF(SUM(IFF(order_status = 'delivered', 1, 0)), 0), 2
    ) AS on_time_pct,

    ROUND(AVG(IFF(
        order_status = 'delivered', 
        DATEDIFF('day', order_purchase_timestamp,
        order_delivered_customer_date), 
        NULL
    )), 1) AS avg_delivery_days
        
FROM order_category
WHERE category IS NOT NULL
GROUP BY category
HAVING COUNT(*) >= 100
ORDER BY orders DESC;

-- =====================================================================
-- Query 12: Review Score by Delivery Performance
-- DOES LATE DELIVERY ACTUALLY CAUSE NEGATIVE REVIEWS?
-- This is the analysis that proves the operational -> satisfaction link
-- ======================================================================

WITH delivery_with_reviews AS (
  SELECT 
    o.order_id,
    DATEDIFF('day', 
      o.order_estimated_delivery_date, 
      o.order_delivered_customer_date
    ) AS delivery_delay_days,
    r.review_score
  FROM RAW.ORDERS o
  INNER JOIN RAW.REVIEWS r ON o.order_id = r.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
),

bucketed AS (
  SELECT 
    CASE 
      WHEN delivery_delay_days <= -5 THEN '1. Very Early (5+ days early)'
      WHEN delivery_delay_days BETWEEN -4 AND -1 THEN '2. Early (1-4 days early)'
      WHEN delivery_delay_days = 0 THEN '3. On Time'
      WHEN delivery_delay_days BETWEEN 1 AND 5 THEN '4. Late (1-5 days)'
      WHEN delivery_delay_days BETWEEN 6 AND 14 THEN '5. Very Late (6-14 days)'
      WHEN delivery_delay_days > 14 THEN '6. Extremely Late (15+ days)'
    END AS delivery_bucket,
    review_score
  FROM delivery_with_reviews
)

SELECT 
  delivery_bucket,
  COUNT(*) AS orders,
  ROUND(AVG(review_score), 2) AS avg_review_score,
  ROUND(SUM(IFF(review_score >= 4, 1, 0)) * 100.0 / COUNT(*), 2) AS positive_review_pct,
  ROUND(SUM(IFF(review_score <= 2, 1, 0)) * 100.0 / COUNT(*), 2) AS negative_review_pct
FROM bucketed
WHERE delivery_bucket IS NOT NULL
GROUP BY delivery_bucket
ORDER BY delivery_bucket;