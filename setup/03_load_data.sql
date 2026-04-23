-- ========================================
-- UPLOAD AND LOAD THE CSVS VIA SnowSQL CLI 
-- Run everything below in your local terminal
-- ========================================

```bash
snowsql -a YOUR_ACCOUNT_IDENTIFIER -u YOUR_USERNAME

USE DATABASE OLIST_ANALYTICS;
USE SCHEMA RAW;
PUT file:///path/to/olist/*.csv @olist_stage AUTO_COMPRESS=TRUE;
```

-- Now load each table from the stage:

```snowsql
-- Load customers
COPY INTO RAW.CUSTOMERS
FROM @olist_stage/olist_customers_dataset.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- Load orders
COPY INTO RAW.ORDERS
FROM @olist_stage/olist_orders_dataset.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- Load order items
COPY INTO RAW.ORDER_ITEMS
FROM @olist_stage/olist_order_items_dataset.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- Load payments
COPY INTO RAW.PAYMENTS
FROM @olist_stage/olist_order_payments_dataset.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- Load reviews (this one has tricky escaping due to Portuguese comments)
COPY INTO RAW.REVIEWS
FROM @olist_stage/olist_order_reviews_dataset.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- Load products
COPY INTO RAW.PRODUCTS
FROM @olist_stage/olist_products_dataset.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- Load sellers
COPY INTO RAW.SELLERS
FROM @olist_stage/olist_sellers_dataset.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- Load category translation
COPY INTO RAW.CATEGORY_TRANSLATION
FROM @olist_stage/product_category_name_translation.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';
```

-- Check for errors**

```snowsql
-- Check load history for any errors
SELECT * 
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME=>'RAW.REVIEWS',
  START_TIME=>DATEADD(hours,-1,CURRENT_TIMESTAMP())
));
```