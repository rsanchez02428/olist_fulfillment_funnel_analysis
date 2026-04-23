USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ===================================================
-- Query 6: Data  Quality Audit
-- Comprehensive data quality checks
-- Run BEFORE analysis - these are professional habits
-- ===================================================

WITH quality_checks AS (
    -- Check 1: Orders with status 'delivered' but no delivery date
    SELECT 
        'delivered_status_no_delivery_date' AS check_name,
        COUNT(*) AS issue_count
    FROM RAW.ORDERS
    WHERE order_status = 'delivered'
        AND order_delivered_customer_date IS NULL

    UNION ALL

    -- Check 2: Orders shipped before they were approved (impossible)
    SELECT
        'shipped_before_approved', 
        COUNT(*)
    FROM RAW.ORDERS
    WHERE order_delivered_carrier_date < order_approved_at

    UNION ALL

    -- Check 3: Orders delivered before they were shipped (impossible)
    SELECT
        'delivered_before_shipped',
        COUNT(*)
    FROM RAW.ORDERS 
    WHERE order_delivered_customer_date < order_delivered_carrier_date

    UNION ALL

    -- Check 4: Orders with no items
    SELECT 
        'orders_without_items',
        COUNT(DISTINCT o.order_id)
    FROM RAW.ORDERS o
    LEFT JOIN RAW.ORDER_ITEMS oi 
    ON o.order_id = oi.order_id
    WHERE oi.order_id IS NULL

    UNION ALL

    -- Check 5: Orders with no payments
    SELECT 
        'orders_without_payments',
        COUNT(DISTINCT o.order_id)
    FROM RAW.ORDERS o 
    LEFT JOIN RAW.PAYMENTS p
    ON o.order_id = p.order_id
    WHERE p.order_id IS NULL

    UNION ALL

    -- Check 6: Reviews for orders that don't exist
    SELECT 'orphan_review',
        COUNT(*)
    FROM RAW.REVIEWS r
    LEFT JOIN RAW.ORDERS o 
    ON r.order_id = o.order_id
    WHERE o.order_id IS NULL
)

SELECT *
FROM quality_checks
ORDER BY issue_count DESC;