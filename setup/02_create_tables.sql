-- ===================
-- CREATE THE 8 TABLES
-- ===================

-- ==== CUSTOMERS ====
CREATE OR REPLACE TABLE RAW.CUSTOMERS (
    customer_id                 VARCHAR,
    customer_unique_id          VARCHAR,
    customer_zip_code_prefix    INT,
    customer_city               VARCHAR, 
    customer_state              VARCHAR(2)
);

-- ============= ORDERS =============
CREATE OR REPLACE TABLE RAW.ORDERS (
  order_id                      VARCHAR,
  customer_id                   VARCHAR,
  order_status                  VARCHAR,
  order_purchase_timestamp      TIMESTAMP,
  order_approved_at             TIMESTAMP,
  order_delivered_carrier_date  TIMESTAMP,
  order_delivered_customer_date TIMESTAMP,
  order_estimated_delivery_date TIMESTAMP
);

-- ============= ORDER_ITEMS =============
CREATE OR REPLACE TABLE RAW.ORDER_ITEMS (
  order_id           VARCHAR,
  order_item_id      INT,
  product_id         VARCHAR,
  seller_id          VARCHAR,
  shipping_limit_date TIMESTAMP,
  price              FLOAT,
  freight_value      FLOAT
);

-- ============= PAYMENTS =============
CREATE OR REPLACE TABLE RAW.PAYMENTS (
  order_id              VARCHAR,
  payment_sequential    INT,
  payment_type          VARCHAR,
  payment_installments  INT,
  payment_value         FLOAT
);

-- ============= REVIEWS =============
CREATE OR REPLACE TABLE RAW.REVIEWS (
  review_id              VARCHAR,
  order_id               VARCHAR,
  review_score           INT,
  review_comment_title   VARCHAR,
  review_comment_message VARCHAR,
  review_creation_date   TIMESTAMP,
  review_answer_timestamp TIMESTAMP
);

-- ============= PRODUCTS =============
CREATE OR REPLACE TABLE RAW.PRODUCTS (
  product_id                  VARCHAR,
  product_category_name       VARCHAR,
  product_name_length         INT,
  product_description_length  INT,
  product_photos_qty          INT,
  product_weight_g            INT,
  product_length_cm           INT,
  product_height_cm           INT,
  product_width_cm            INT
);

-- ============= SELLERS =============
CREATE OR REPLACE TABLE RAW.SELLERS (
  seller_id                VARCHAR,
  seller_zip_code_prefix   INT,
  seller_city              VARCHAR,
  seller_state             VARCHAR(2)
);

-- ============= CATEGORY TRANSLATION =============
-- Olist categories are in Portuguese — this maps to English
CREATE OR REPLACE TABLE RAW.CATEGORY_TRANSLATION (
  product_category_name          VARCHAR,
  product_category_name_english  VARCHAR
);