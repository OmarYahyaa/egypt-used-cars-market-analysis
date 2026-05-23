/*
===============================================================================
Project: Egypt Used Cars Market Analysis
Script: 08_insert_star_schema.sql
Purpose: Populate the analysis/reporting star schema from the clean layer
Database: egypt_used_cars_db
Schemas: clean, analysis
===============================================================================

This script:
- loads descriptive dimension tables from analysis-ready clean records,
- loads fixed business-rule dimensions for mileage and budget segments,
- loads analysis.fact_listed_car with one row per analysis-ready listing,
- loads analysis.bridge_listing_feature to handle the many-to-many relationship
  between listings and features.

Important:
- The analysis model is built from records where is_analysis_ready = TRUE.
- source_* columns preserve source-listed values in the clean layer.
- clean_* columns store typed analytical values in the clean layer.
- source_features is split by the pipe delimiter (|) before loading the feature
  bridge table.
===============================================================================
*/


/*
===============================================================================
1. Load Dimension Tables
===============================================================================
*/


/*
-------------------------------------------------------------------------------
1.1 Load dim_company
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_company (company_name)
SELECT DISTINCT
    TRIM(source_company) AS company_name
FROM clean.clean_used_car_listings_aug_2025
WHERE is_analysis_ready = TRUE
ORDER BY company_name ASC;


/*
-------------------------------------------------------------------------------
1.2 Load dim_model
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_model (model_name)
SELECT DISTINCT
    TRIM(source_model) AS model_name
FROM clean.clean_used_car_listings_aug_2025
WHERE is_analysis_ready = TRUE
ORDER BY model_name ASC;


/*
-------------------------------------------------------------------------------
1.3 Load dim_manufacturing_year
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_manufacturing_year (manufacturing_year)
SELECT DISTINCT
    clean_manufacturing_year AS manufacturing_year
FROM clean.clean_used_car_listings_aug_2025
WHERE is_analysis_ready = TRUE
ORDER BY manufacturing_year ASC;


/*
-------------------------------------------------------------------------------
1.4 Load dim_color
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_color (color_name)
SELECT DISTINCT
    TRIM(source_color) AS color_name
FROM clean.clean_used_car_listings_aug_2025
WHERE is_analysis_ready = TRUE
ORDER BY color_name ASC;


/*
-------------------------------------------------------------------------------
1.5 Load dim_location
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_location (location_name)
SELECT DISTINCT
    TRIM(clean_location) AS location_name
FROM clean.clean_used_car_listings_aug_2025
WHERE is_analysis_ready = TRUE
ORDER BY location_name ASC;


/*
-------------------------------------------------------------------------------
1.6 Load dim_feature

source_features is a multi-value text field, for example:
    Automatic | Air Conditioner | Remote Control

The field is split by the pipe delimiter (|), expanded into individual feature
values, trimmed, deduplicated, and loaded into dim_feature.
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_feature (feature_name)
SELECT DISTINCT
    TRIM(feature_value.feature_name_raw) AS feature_name
FROM clean.clean_used_car_listings_aug_2025 AS ct
CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(ct.source_features, '|')) AS feature_value(feature_name_raw)
WHERE ct.is_analysis_ready = TRUE
  AND ct.source_features IS NOT NULL
  AND UPPER(TRIM(ct.source_features)) NOT IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
  AND TRIM(feature_value.feature_name_raw) <> ''
ORDER BY feature_name ASC;


/*
-------------------------------------------------------------------------------
1.7 Load dim_mileage_category

The upper boundary is NULL for the open-ended highest category.
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_mileage_category (
    mileage_category,
    mileage_lower_boundary_km,
    mileage_upper_boundary_km,
    mileage_category_order
)
VALUES
    ('Low mileage', 0, 50000, 1),
    ('Moderate mileage', 50000, 150000, 2),
    ('High mileage', 150000, NULL, 3);


/*
-------------------------------------------------------------------------------
1.8 Load dim_budget_segment

The upper boundary is NULL for the open-ended premium segment.
-------------------------------------------------------------------------------
*/

INSERT INTO analysis.dim_budget_segment (
    budget_segment,
    budget_lower_boundary_egp,
    budget_upper_boundary_egp,
    budget_segment_order
)
VALUES
    ('Very low budget', 0, 300000, 1),
    ('Low budget', 300000, 600000, 2),
    ('Mid budget', 600000, 1000000, 3),
    ('High budget', 1000000, 2000000, 4),
    ('Premium budget', 2000000, NULL, 5);


/*
===============================================================================
2. Load Fact Table
===============================================================================

Grain:
    One row per analysis-ready car listing.

Range-dimension logic:
    A row belongs to a category when its value is greater than or equal to the
    lower boundary and less than the upper boundary.

    COALESCE(< upper boundary comparison>, TRUE) handles open-ended ranges where
    the upper boundary is NULL.
===============================================================================
*/

INSERT INTO analysis.fact_listed_car (
    raw_listing_id,
    company_id,
    model_id,
    manufacturing_year_id,
    color_id,
    location_id,
    mileage_category_id,
    budget_segment_id,
    mileage_km,
    price_egp
)
SELECT
    ct.raw_listing_id,
    c.company_id,
    m.model_id,
    my.manufacturing_year_id,
    co.color_id,
    l.location_id,
    mc.mileage_category_id,
    bs.budget_segment_id,
    ct.clean_mileage_km,
    ct.clean_price_egp
FROM clean.clean_used_car_listings_aug_2025 AS ct
LEFT JOIN analysis.dim_company AS c
    ON TRIM(ct.source_company) = c.company_name
LEFT JOIN analysis.dim_model AS m
    ON TRIM(ct.source_model) = m.model_name
LEFT JOIN analysis.dim_manufacturing_year AS my
    ON ct.clean_manufacturing_year = my.manufacturing_year
LEFT JOIN analysis.dim_color AS co
    ON TRIM(ct.source_color) = co.color_name
LEFT JOIN analysis.dim_location AS l
    ON TRIM(ct.clean_location) = l.location_name
LEFT JOIN analysis.dim_mileage_category AS mc
    ON ct.clean_mileage_km >= mc.mileage_lower_boundary_km
   AND COALESCE(ct.clean_mileage_km < mc.mileage_upper_boundary_km, TRUE)
LEFT JOIN analysis.dim_budget_segment AS bs
    ON ct.clean_price_egp >= bs.budget_lower_boundary_egp
   AND COALESCE(ct.clean_price_egp < bs.budget_upper_boundary_egp, TRUE)
WHERE ct.is_analysis_ready = TRUE;


/*
===============================================================================
3. Load Bridge Table
===============================================================================

Purpose:
    Resolve the many-to-many relationship between listings and features.

Logic:
    - Start from fact_listed_car so only analysis-ready listings are included.
    - Join back to the clean table to access source_features.
    - Exclude missing-like feature values because they do not represent real
      feature information.
    - Split source_features by | and trim each extracted feature.
    - Join extracted feature names to dim_feature to get feature_id.
===============================================================================
*/

INSERT INTO analysis.bridge_listing_feature (
    raw_listing_id,
    feature_id
)
SELECT
    extracted.raw_listing_id,
    f.feature_id
FROM (
    SELECT
        ft.raw_listing_id,
        TRIM(feature_value.feature_name_raw) AS extracted_feature
    FROM analysis.fact_listed_car AS ft
    INNER JOIN clean.clean_used_car_listings_aug_2025 AS ct
        USING (raw_listing_id)
    CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(ct.source_features, '|')) AS feature_value(feature_name_raw)
    WHERE ct.source_features IS NOT NULL
      AND UPPER(TRIM(ct.source_features)) NOT IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
      AND TRIM(feature_value.feature_name_raw) <> ''
) AS extracted
INNER JOIN analysis.dim_feature AS f
    ON extracted.extracted_feature = f.feature_name;


/*
===============================================================================
4. Validation Checks
===============================================================================
*/


/*
-------------------------------------------------------------------------------
4.1 Dimension row counts
-------------------------------------------------------------------------------
*/

SELECT 'dim_company' AS table_name, COUNT(*) AS row_count FROM analysis.dim_company
UNION ALL
SELECT 'dim_model', COUNT(*) FROM analysis.dim_model
UNION ALL
SELECT 'dim_manufacturing_year', COUNT(*) FROM analysis.dim_manufacturing_year
UNION ALL
SELECT 'dim_color', COUNT(*) FROM analysis.dim_color
UNION ALL
SELECT 'dim_location', COUNT(*) FROM analysis.dim_location
UNION ALL
SELECT 'dim_feature', COUNT(*) FROM analysis.dim_feature
UNION ALL
SELECT 'dim_mileage_category', COUNT(*) FROM analysis.dim_mileage_category
UNION ALL
SELECT 'dim_budget_segment', COUNT(*) FROM analysis.dim_budget_segment
ORDER BY table_name;


/*
-------------------------------------------------------------------------------
4.2 Fact row count should match analysis-ready clean rows
-------------------------------------------------------------------------------
*/

SELECT
    'fact_listed_car' AS check_name,
    COUNT(*) AS row_count
FROM analysis.fact_listed_car

UNION ALL

SELECT
    'analysis_ready_clean_rows' AS check_name,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
WHERE is_analysis_ready = TRUE;


/*
-------------------------------------------------------------------------------
4.3 Fact foreign-key match validation

All matched counts should equal total_rows.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS total_rows,
    COUNT(company_id) AS matched_company,
    COUNT(model_id) AS matched_model,
    COUNT(manufacturing_year_id) AS matched_year,
    COUNT(color_id) AS matched_color,
    COUNT(location_id) AS matched_location,
    COUNT(mileage_category_id) AS matched_mileage_category,
    COUNT(budget_segment_id) AS matched_budget_segment
FROM analysis.fact_listed_car;


/*
-------------------------------------------------------------------------------
4.4 Bridge table validation
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS bridge_rows,
    COUNT(DISTINCT raw_listing_id) AS listings_with_features,
    COUNT(DISTINCT feature_id) AS unique_features_used
FROM analysis.bridge_listing_feature;
