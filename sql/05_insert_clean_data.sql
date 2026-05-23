/*
===============================================================================
Project: Egypt Used Cars Market Analysis
Script: 05_insert_clean_data.sql
Purpose: Insert transformed data from raw layer into clean layer
Database: egypt_used_cars_db
Schema: clean
===============================================================================

This script:
- reads from raw.raw_used_car_listings_aug_2025
- inserts into clean.clean_used_car_listings_aug_2025
- preserves source values for auditability using source_* columns
- creates clean analytical columns using clean_* columns
- creates quality flags
- keeps all rows and flags quality issues instead of deleting them

Important:
- cleaned_at is not inserted manually.
- PostgreSQL fills cleaned_at automatically using DEFAULT NOW().
- This script assumes the clean table is empty. Re-run 04_create_clean_table.sql
  before re-running this script.
===============================================================================
*/


/*
===============================================================================
1. Insert clean data
===============================================================================
*/

WITH base_data AS (
    SELECT
        raw_listing_id,
        detail_link,
        source_file_name,
        loaded_at,

        title AS source_title,
        company AS source_company,
        model AS source_model,
        color AS source_color,

        year AS source_year,
        price AS source_price,
        mileage AS source_mileage,
        location AS source_location,
        features AS source_features,
        transmission AS source_transmission,
        date_posted AS source_date_posted,

        ROW_NUMBER() OVER (
            PARTITION BY detail_link
            ORDER BY raw_listing_id
        ) AS duplicate_sequence,

        COUNT(*) OVER (
            PARTITION BY detail_link
        ) AS link_count

    FROM raw.raw_used_car_listings_aug_2025
),

duplicate_flags AS (
    SELECT
        *,
        CASE
            WHEN link_count = 1
                THEN 'unique_detail_link'
            WHEN link_count > 1
             AND duplicate_sequence = 1
                THEN 'duplicate_detail_link_keep_first'
            WHEN link_count > 1
             AND duplicate_sequence > 1
                THEN 'duplicate_detail_link_extra_row'
        END AS duplicate_quality_flag

    FROM base_data
),

price_cleaning AS (
    SELECT
        *,
        CASE
            WHEN source_price IS NULL
              OR UPPER(TRIM(source_price)) IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
                THEN NULL
            ELSE TRIM(
                REPLACE(
                    REPLACE(UPPER(TRIM(source_price)), 'EGP', ''),
                    ',',
                    ''
                )
            )
        END AS cleaned_price_text

    FROM duplicate_flags
),

price_numeric AS (
    SELECT
        *,
        CASE
            WHEN cleaned_price_text ~ '^[0-9]+$'
                THEN cleaned_price_text::NUMERIC
            ELSE NULL
        END AS clean_price_egp

    FROM price_cleaning
),

price_flags AS (
    SELECT
        *,
        CASE
            WHEN cleaned_price_text IS NULL
                THEN 'missing_price'
            WHEN cleaned_price_text !~ '^[0-9]+$'
                THEN 'invalid_price_format'
            WHEN clean_price_egp < 50000
                THEN 'suspicious_low_price'
            WHEN clean_price_egp > 20000000
                THEN 'suspicious_high_price'
            ELSE 'valid_price'
        END AS price_quality_flag

    FROM price_numeric
),

mileage_cleaning AS (
    SELECT
        *,
        CASE
            WHEN source_mileage IS NULL
              OR UPPER(TRIM(source_mileage)) IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
                THEN NULL
            ELSE TRIM(
                REPLACE(
                    REPLACE(UPPER(TRIM(source_mileage)), 'KM', ''),
                    ',',
                    ''
                )
            )
        END AS cleaned_mileage_text

    FROM price_flags
),

mileage_numeric AS (
    SELECT
        *,
        CASE
            WHEN cleaned_mileage_text ~ '^[0-9]+$'
                THEN cleaned_mileage_text::NUMERIC
            ELSE NULL
        END AS clean_mileage_km

    FROM mileage_cleaning
),

mileage_flags AS (
    SELECT
        *,
        CASE
            WHEN cleaned_mileage_text IS NULL
                THEN 'missing_mileage'
            WHEN cleaned_mileage_text !~ '^[0-9]+$'
                THEN 'invalid_mileage_format'
            WHEN clean_mileage_km = 0
                THEN 'zero_mileage'
            WHEN clean_mileage_km = 1
                THEN 'one_km_mileage'
            WHEN clean_mileage_km > 500000
                THEN 'suspicious_high_mileage'
            ELSE 'valid_mileage'
        END AS mileage_quality_flag

    FROM mileage_numeric
),

year_numeric AS (
    SELECT
        *,
        CASE
            WHEN TRIM(source_year) ~ '^[0-9]+$'
                THEN TRIM(source_year)::SMALLINT
            ELSE NULL
        END AS numeric_year

    FROM mileage_flags
),

year_cleaning AS (
    SELECT
        *,
        CASE
            WHEN numeric_year BETWEEN 1950 AND 2026
                THEN numeric_year
            ELSE NULL
        END AS clean_manufacturing_year

    FROM year_numeric
),

year_flags AS (
    SELECT
        *,
        CASE
            WHEN source_year IS NULL
              OR TRIM(source_year) = ''
              OR UPPER(TRIM(source_year)) IN ('NA', 'N/A', 'UNKNOWN', '-')
                THEN 'missing_year'
            WHEN numeric_year IS NULL
                THEN 'invalid_year_format'
            WHEN numeric_year < 1950
                THEN 'invalid_old_year'
            WHEN numeric_year > 2026
                THEN 'invalid_future_year'
            ELSE 'valid_year'
        END AS year_quality_flag

    FROM year_cleaning
),

date_cleaning AS (
    SELECT
        *,
        CASE
            WHEN source_date_posted IS NULL
              OR UPPER(TRIM(source_date_posted)) IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
                THEN NULL
            WHEN TRIM(source_date_posted) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                THEN TRIM(source_date_posted)::DATE
            ELSE NULL
        END AS clean_date_posted

    FROM year_flags
),

date_flags AS (
    SELECT
        *,
        CASE
            WHEN source_date_posted IS NULL
              OR UPPER(TRIM(source_date_posted)) IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
                THEN 'missing_date'
            WHEN clean_date_posted IS NULL
                THEN 'invalid_date_format'
            ELSE 'valid_date'
        END AS date_quality_flag

    FROM date_cleaning
),

location_cleaning AS (
    SELECT
        *,
        CASE
            WHEN source_location IS NULL
              OR UPPER(TRIM(source_location)) IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
                THEN NULL
            WHEN source_title ILIKE '%' || TRIM(source_location) || '%'
                THEN NULL
            ELSE TRIM(source_location)
        END AS clean_location

    FROM date_flags
),

location_flags AS (
    SELECT
        *,
        CASE
            WHEN source_location IS NULL
              OR UPPER(TRIM(source_location)) IN ('', 'NA', 'N/A', 'UNKNOWN', '-')
                THEN 'missing_location'
            WHEN source_title ILIKE '%' || TRIM(source_location) || '%'
                THEN 'likely_model_in_location'
            ELSE 'valid_location'
        END AS location_quality_flag

    FROM location_cleaning
),

analysis_ready AS (
    SELECT
        *,
        CASE
            WHEN price_quality_flag = 'valid_price'
             AND mileage_quality_flag = 'valid_mileage'
             AND year_quality_flag = 'valid_year'
             AND location_quality_flag = 'valid_location'
             AND date_quality_flag = 'valid_date'
             AND duplicate_quality_flag <> 'duplicate_detail_link_extra_row'
                THEN TRUE
            ELSE FALSE
        END AS is_analysis_ready

    FROM location_flags
)

INSERT INTO clean.clean_used_car_listings_aug_2025 (
    raw_listing_id,
    detail_link,
    source_file_name,
    loaded_at,

    source_title,
    source_company,
    source_model,
    source_color,

    source_year,
    source_price,
    source_mileage,
    source_location,
    source_features,
    source_transmission,
    source_date_posted,

    clean_manufacturing_year,
    clean_price_egp,
    clean_mileage_km,
    clean_location,
    clean_date_posted,

    year_quality_flag,
    price_quality_flag,
    mileage_quality_flag,
    location_quality_flag,
    date_quality_flag,
    duplicate_quality_flag,
    is_analysis_ready
)
SELECT
    raw_listing_id,
    detail_link,
    source_file_name,
    loaded_at,

    source_title,
    source_company,
    source_model,
    source_color,

    source_year,
    source_price,
    source_mileage,
    source_location,
    source_features,
    source_transmission,
    source_date_posted,

    clean_manufacturing_year,
    clean_price_egp,
    clean_mileage_km,
    clean_location,
    clean_date_posted,

    year_quality_flag,
    price_quality_flag,
    mileage_quality_flag,
    location_quality_flag,
    date_quality_flag,
    duplicate_quality_flag,
    is_analysis_ready

FROM analysis_ready;


/*
===============================================================================
2. Validation checks after insert
===============================================================================
*/


/*
2.1 Row count validation
Expected:
- raw_rows = 24,688
- clean_rows = 24,688
*/

SELECT
    'raw_table' AS table_name,
    COUNT(*) AS row_count
FROM raw.raw_used_car_listings_aug_2025

UNION ALL

SELECT
    'clean_table' AS table_name,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025;


/*
2.2 Analysis readiness distribution
*/

SELECT
    is_analysis_ready,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
GROUP BY is_analysis_ready
ORDER BY is_analysis_ready DESC;


/*
2.3 Duplicate quality flag distribution
Expected:
- unique_detail_link = 24,496
- duplicate_detail_link_keep_first = 61
- duplicate_detail_link_extra_row = 131
*/

SELECT
    duplicate_quality_flag,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
GROUP BY duplicate_quality_flag
ORDER BY row_count DESC;


/*
2.4 Price quality flag distribution
Expected:
- valid_price = 24,462
- missing_price = 109
- suspicious_low_price = 108
- suspicious_high_price = 9
*/

SELECT
    price_quality_flag,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
GROUP BY price_quality_flag
ORDER BY row_count DESC;


/*
2.5 Mileage quality flag distribution
Expected:
- valid_mileage = 23,010
- missing_mileage = 1,410
- zero_mileage = 131
- suspicious_high_mileage = 127
- one_km_mileage = 10
*/

SELECT
    mileage_quality_flag,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
GROUP BY mileage_quality_flag
ORDER BY row_count DESC;


/*
2.6 Year quality flag distribution
Expected:
- valid_year = 24,322
- invalid_future_year = 349
- invalid_old_year = 11
- missing_year = 6
*/

SELECT
    year_quality_flag,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
GROUP BY year_quality_flag
ORDER BY row_count DESC;


/*
2.7 Date quality flag distribution
Expected:
- valid_date = 24,688
*/

SELECT
    date_quality_flag,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
GROUP BY date_quality_flag
ORDER BY row_count DESC;


/*
2.8 Location quality flag distribution
Expected:
- valid_location = 24,582
- likely_model_in_location = 106
*/

SELECT
    location_quality_flag,
    COUNT(*) AS row_count
FROM clean.clean_used_car_listings_aug_2025
GROUP BY location_quality_flag
ORDER BY row_count DESC;


/*
2.9 Metadata validation
Expected all counts = 24,688
*/

SELECT
    COUNT(*) AS total_rows,
    COUNT(raw_listing_id) AS raw_listing_ids,
    COUNT(source_file_name) AS source_file_names,
    COUNT(loaded_at) AS loaded_timestamps,
    COUNT(cleaned_at) AS cleaned_timestamps
FROM clean.clean_used_car_listings_aug_2025;
