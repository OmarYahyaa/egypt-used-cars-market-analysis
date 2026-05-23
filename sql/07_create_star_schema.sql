/*
===============================================================================
SQL Script: 07_create_analysis_model.sql
Project: Egypt Used Cars Market Analysis
Purpose:
    Create the Phase 2 analysis/reporting model.

    This script builds a star-schema-style analytical layer in the analysis schema.
    The model is designed for reporting and future Power BI use.

Modeling approach:
    - Dimension tables store descriptive attributes.
    - The fact table stores one row per analysis-ready car listing.
    - The bridge table handles the many-to-many relationship between listings
      and features.

Grain:
    fact_listed_car has one row per analysis-ready car listing.

Important:
    This script only creates the model structure.
    Data loading will be handled in the next script.
===============================================================================
*/

SET search_path TO analysis;


/*
===============================================================================
1. Dimension Tables
===============================================================================
*/

CREATE TABLE dim_company (
    company_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name TEXT NOT NULL UNIQUE
);


CREATE TABLE dim_model (
    model_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    model_name TEXT NOT NULL UNIQUE
);


CREATE TABLE dim_manufacturing_year (
    manufacturing_year_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    manufacturing_year SMALLINT NOT NULL UNIQUE
);


CREATE TABLE dim_color (
    color_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    color_name TEXT NOT NULL UNIQUE
);


CREATE TABLE dim_location (
    location_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_area TEXT NOT NULL UNIQUE
);


CREATE TABLE dim_feature (
    feature_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    feature_name TEXT NOT NULL UNIQUE
);


CREATE TABLE dim_mileage_category (
    mileage_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mileage_category TEXT NOT NULL UNIQUE,
    mileage_lower_boundary_km NUMERIC NOT NULL,
    mileage_upper_boundary_km NUMERIC,
    mileage_category_order SMALLINT NOT NULL UNIQUE
);


CREATE TABLE dim_budget_segment (
    budget_segment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    budget_segment TEXT NOT NULL UNIQUE,
    budget_lower_boundary_egp NUMERIC NOT NULL,
    budget_upper_boundary_egp NUMERIC,
    budget_segment_order SMALLINT NOT NULL UNIQUE
);


/*
===============================================================================
2. Fact Table
===============================================================================
*/

CREATE TABLE fact_listed_car (
    raw_listing_id BIGINT PRIMARY KEY
        REFERENCES clean.clean_used_car_listings_aug_2025(raw_listing_id),

    company_id BIGINT
        REFERENCES analysis.dim_company(company_id),

    model_id BIGINT
        REFERENCES analysis.dim_model(model_id),

    manufacturing_year_id BIGINT
        REFERENCES analysis.dim_manufacturing_year(manufacturing_year_id),

    color_id BIGINT
        REFERENCES analysis.dim_color(color_id),

    location_id BIGINT
        REFERENCES analysis.dim_location(location_id),

    mileage_category_id BIGINT
        REFERENCES analysis.dim_mileage_category(mileage_category_id),

    budget_segment_id BIGINT
        REFERENCES analysis.dim_budget_segment(budget_segment_id),

    mileage_km NUMERIC NOT NULL,
    price_egp NUMERIC NOT NULL
);


/*
===============================================================================
3. Bridge Table
===============================================================================
*/

CREATE TABLE bridge_listing_feature (
    raw_listing_id BIGINT NOT NULL
        REFERENCES analysis.fact_listed_car(raw_listing_id),

    feature_id BIGINT NOT NULL
        REFERENCES analysis.dim_feature(feature_id),

    PRIMARY KEY (raw_listing_id, feature_id)
);


/*
===============================================================================
4. Structure Validation
===============================================================================
*/

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'analysis'
ORDER BY table_name, ordinal_position;
