USE WAREHOUSE ANALYST_WH;
USE DATABASE OLIST_ANALYTICS;
USE SCHEMA OLIST_ANALYTICS.RAW;

-- ====================================================================
-- Query 10: Funnel by Payment Type
-- DOES PAYMNET METHOD AFFECT THE FUNNEL?
-- Boleto (Brazilian bank slip) takes longer to confirm than credit card
-- =====================================================================

With order_payment AS (
    -- Get the PRIMARY payment type per order (handle multi-payment orders)
    SELECT
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_customer_date,
        p.payment_type,
        p.payment_installments
    FROM RAW.ORDERS o 
    INNER JOIN RAW.PAYMENTS p 
    ON o.order_id = p.order_id
    QUALIFY ROW_NUMBER() OVER(
        PARTITION BY o.order_id
        ORDER BY p.payment_value DESC
    ) = 1 -- Take the largest payment per order
)

SELECT 
    payment_type,
    COUNT(*) AS orders,

    -- Funnel rates per payment type
    ROUND(SUM(IFF(order_approved_at IS NOT NULL, 1, 0)) * 100.0 / COUNT(*), 2)
        AS approval_rate,
    ROUND(SUM(IFF(order_status = 'delivered', 1, 0)) * 100.0 / COUNT(*), 2)
        AS delivery_rate, 
    ROUND(SUM(IFF(order_status = 'canceled', 1, 0)) * 100.0 / COUNT(*), 2)
        AS cancellation_rate,

    -- Average approval time
    ROUND(AVG(DATEDIFF('hour', order_purchase_timestamp, order_approved_at)), 1)
        AS avg_hours_to_approve
FROM order_payment
GROUP BY payment_type
ORDER BY orders DESC;