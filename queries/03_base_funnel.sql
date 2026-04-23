USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ===========================================================
-- Query 7: The Core Fulfillment Funnel
-- THE CORE FUNNEL QUERY - the most important deliverable
-- Shows users at each fulfillment stage with conversion rates
-- ===========================================================

WITH funnel_counts AS (
  SELECT 
    -- Stage 1: Total orders created
    COUNT(*) AS step_1_created,
    
    -- Stage 2: Orders approved (payment processed)
    COUNT(IFF(order_approved_at IS NOT NULL, 1, NULL)) AS step_2_approved,
    
    -- Stage 3: Orders shipped (handed to carrier)
    COUNT(IFF(order_delivered_carrier_date IS NOT NULL, 1, NULL)) AS step_3_shipped,
    
    -- Stage 4: Orders delivered to customer
    COUNT(IFF(order_delivered_customer_date IS NOT NULL, 1, NULL)) AS step_4_delivered
    
  FROM RAW.ORDERS
),

with_reviews AS (
  -- Stage 5: Orders with a positive review (4 or 5 stars)
  SELECT 
    fc.*,
    (SELECT COUNT(DISTINCT o.order_id) 
     FROM RAW.ORDERS o
     INNER JOIN RAW.REVIEWS r ON o.order_id = r.order_id
     WHERE r.review_score >= 4 
       AND o.order_delivered_customer_date IS NOT NULL
    ) AS step_5_positive_review
  FROM funnel_counts fc
),

unpivoted AS (
  SELECT 1 AS step_num, 'Created' AS step_name, step_1_created AS users FROM with_reviews
  UNION ALL SELECT 2, 'Approved', step_2_approved FROM with_reviews
  UNION ALL SELECT 3, 'Shipped', step_3_shipped FROM with_reviews
  UNION ALL SELECT 4, 'Delivered', step_4_delivered FROM with_reviews
  UNION ALL SELECT 5, 'Positive Review', step_5_positive_review FROM with_reviews
)

SELECT 
  step_num,
  step_name,
  users,
  
  -- Percent of total starting users
  ROUND(users * 100.0 / FIRST_VALUE(users) OVER(ORDER BY step_num), 2) 
    AS pct_of_total,
  
  -- Step-over-step conversion rate
  ROUND(users * 100.0 / NULLIF(LAG(users) OVER(ORDER BY step_num), 0), 2) 
    AS step_conversion_pct,
  
  -- Users lost at this stage
  LAG(users) OVER(ORDER BY step_num) - users AS users_lost,
  
  -- Drop-off rate from previous step
  ROUND(
    (LAG(users) OVER(ORDER BY step_num) - users) * 100.0 / 
    NULLIF(LAG(users) OVER(ORDER BY step_num), 0), 2
  ) AS drop_off_pct

FROM unpivoted
ORDER BY step_num;

-- =================================================
-- Query 8: Time Between Funnel Stage
-- How long does each funnel stage take, on average?
-- Long stages = potential customer dissatisfaction
-- =================================================

SELECT 
    -- Stage 1 -> 2: Time from purchase to payment approval
    ROUND(AVG(DATEDIFF('hour',
        order_purchase_timestamp,
        order_approved_at
        )), 1) AS avg_hours_to_approval,
        
    ROUND(MEDIAN(DATEDIFF('hour',
    order_purchase_timestamp,
    order_approved_at
    )), 1) AS median_hours_to_approval,

    -- Stage 2 -> 3: Time from approval to shipping
    ROUND(AVG(DATEDIFF('day',
    order_approved_at, 
    order_delivered_carrier_date
    )), 1) AS avg_days_to_ship,

    -- Stage 3 -> 4: Time from shipping to delivery
    ROUND(AVG(DATEDIFF('day', 
    order_delivered_carrier_date,
    order_delivered_customer_date
    )), 1) AS avg_days_in_transit,

    -- Total: Time from purchase to delivery
    ROUND(AVG(DATEDIFF('day',
    order_purchase_timestamp,
    order_delivered_customer_date
    )), 1) AS avg_days_total,

    -- Estimated vs actual: how often does Olist beat its own estimate?
    ROUND(SUM(IFF(
        order_delivered_customer_date <=
        order_estimated_delivery_date, 1, 0
    )) * 100.0 / COUNT(*), 2) AS on_time_delivery_pct
    
FROM RAW.ORDERS
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL