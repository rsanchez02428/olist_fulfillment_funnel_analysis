-- =============================================
-- INITIAL SETUP
-- Run these once to create project environment
-- =============================================

-- Create a database for this project
CREATE DATABASE IF NOT EXISTS OLIST_ANALYTICS;

-- Use it
USE DATABASE OLIST_ANALYTICS;

-- Create schemas to organize your work
CREATE SCHEMA IF NOT EXISTS RAW;    -- Raw Olist data is loaded
CREATE SCHEMA IF NOT EXISTS ANALYTICS; -- Cleaned/ transformed data

-- Create a small virtual warehouse for your queries
-- XS = Extra Small = cheapest option, plenty fast for 100K rows
CREATE WAREHOUSE IF NOT EXISTS ANALYST_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60   -- Suspends after 60 second of no use (saves credits)
  AUTO_RESUME = TRUE  -- Automatically starts when you run a query
  INITIALLY_SUSPENDED = TRUE; 

-- Set your context (which database/schema/warehouse to use)
USE WAREHOUSE ANALYST_WH;
USE SCHEMA OLIST_ANALYTICS.RAW; 

-- ============================
-- Define File Format and Stage 
-- ============================

-- File format for CSV files (reusable)
CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', 'NA')
    EMPTY_FIELD_AS_NULL = TRUE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO'
    ESCAPE_UNENCLOSED_FIELD = NONE; --Olist data has special chard in product names

-- Internal stage (file landing zone within Snowflake)
CREATE OR REPLACE STAGE olist_stage
    FILE_FORMAT = csv_format;

