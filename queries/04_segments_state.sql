USE WAREHOUSE ANALYST_WH; 
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ===========================================================
-- Query 9: Funnel by Customer State
-- DELIVERY SUCCESS BY CUSTOMER STATE
-- Which Brazilian states have the worst delivery experience?
-- ===========================================================

SELECT 
    c.customer_state, 
    COUNT(*) AS total_orders,

    SUM(IFF(o.order_status = 'delivered', 1, 0)) AS delivered,
    SUM(IFF(o.order_status = 'canceled', 1, 0)) AS canceled,
    SUM(IFF(o.order_status NOT IN ('delivered', 'canceled'), 1, 0)) AS stuck_in_pipeline,
    -- Delivery rate
    ROUND(SUM(IFF(o.order_status = 'delivered', 1, 0)) * 100.0 / COUNT(*), 2) AS delivery_rate_pct,

    -- On-time delivery rate (delivered orders only)
    ROUND(
        SUM(IFF(o.order_delivered_customer_date <= o.order_estimated_delivery_date, 1, 0)) * 100.0 / 
        NULLIF(SUM(IFF(o.order_status = 'delivered', 1, 0)), 0), 2
        ) AS on_time_pct,

    -- Average delivery time
    ROUND(AVG(IFF(
        o.order_status = 'delivered',
        DATEDIFF('day', o.order_purchase_timestamp, o.order_delivered_customer_date),
        NULL
    )), 1) AS avg_delivery_days
    
FROM RAW.ORDERS o
INNER JOIN RAW.CUSTOMERS c
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING COUNT(*) >= 100 -- Filter tiny segments
ORDER BY total_orders DESC;

