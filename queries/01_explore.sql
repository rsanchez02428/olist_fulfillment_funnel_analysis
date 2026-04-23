USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ==================================
-- Query 1: Profile the Orders Table
-- ==================================

USE SCHEMA OLIST_ANALYTICS.RAW;

-- Profile every key column in the orders table
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers, 
    COUNT(DISTINCT order_id) AS unique_orders, 

    -- Date range
    MIN(order_purchase_timestamp)::DATE AS first_order,
    MAX(order_purchase_timestamp)::DATE AS last_order,
    DATEDIFF('day', 
        MIN(order_purchase_timestamp),
        MAX(order_purchase_timestamp)) AS days_span,
        
    -- Null rates for critical fields
    ROUND(SUM(IFF(order_approved_at IS NULL, 1, 0)) * 100.0 / COUNT(*), 2)
        AS pct_never_approved, 
    ROUND(SUM(IFF(order_delivered_carrier_date IS NULL, 1, 0)) * 100.0 / COUNT(*), 2)
        AS pct_never_shipped,
    ROUND(SUM(IFF(order_delivered_customer_date IS NULL, 1, 0)) * 100.0 / COUNT(*), 2)
        AS pct_never_delivered
FROM RAW.ORDERS;

-- ==========================================================
-- Query 2: Understand the Order Status Distribution 
-- WHAT VALUES exist in order_status, and how common is each?
-- This is the foundation of the funnel analysis
-- ==========================================================

SELECT 
    order_status,
    COUNT(*) AS order_count, 
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM RAW.ORDERS
GROUP BY order_status
ORDER BY order_count DESC;

-- ======================================
-- Query 3: Daily Order Volume and Trends
-- Daily order with 7-day rolling average
-- ======================================

SELECT
    order_purchase_timestamp::DATE AS order_date,
    COUNT(*) AS daily_orders, 
    SUM(IFF(order_status = 'delivered', 1, 0)) AS daily_delivered, 
    SUM(IFF(order_status = 'canceled', 1, 0)) AS daily_canceled,
    
    -- 7-day rolling average
    ROUND(AVG(COUNT(*)) OVER(
        ORDER BY order_purchase_timestamp::DATE
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
), 1) AS rolling_7d_avg

FROM RAW.ORDERS
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY order_date
ORDER BY order_date desc;

-- =========================================
-- Query 4: Customer geographic distribution
-- Where are Olist's customers located?
-- =========================================

SELECT
    customer_state,
    COUNT(*) AS customers, 
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM RAW.CUSTOMERS
GROUP BY customer_state
ORDER BY customers DESC
LIMIT 10;

-- ====================================
-- Query 5: Payment Method Distribution
-- How do Olist customers pay?
-- ====================================

SELECT
    payment_type,
    COUNT(*) as payment_records, 
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(AVG(payment_value), 2) AS avg_payment,
    ROUND(AVG(payment_installments), 2) AS avg_installments,
    ROUND(SUM(payment_value), 2) AS total_value
    
FROM RAW.PAYMENTS
GROUP BY payment_type
ORDER BY total_value DESC;
