/*
===============================================================================
06_analysis_questions.sql
Egypt Used Cars Market Analysis
===============================================================================

Purpose:
Answer the core business questions of the Egypt used cars market using the
refactored clean layer.

Default table:
clean.clean_used_car_listings_aug_2025

Default analysis filter:
WHERE is_analysis_ready = TRUE

Clean layer naming convention:
- source_* columns preserve original source values.
- clean_* columns store typed analytical values.
===============================================================================
*/


/*
===============================================================================
Q1. Listed price by manufacturing year
===============================================================================
*/

SELECT
    clean_manufacturing_year AS manufacturing_year,
    COUNT(*) AS number_of_listings,
    MIN(clean_price_egp) AS minimum_listed_price,
    TRUNC(AVG(clean_price_egp)) AS average_listed_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp) AS median_listed_price,
    MAX(clean_price_egp) AS maximum_listed_price,
    MAX(clean_price_egp) - MIN(clean_price_egp) AS price_gap
FROM clean.clean_used_car_listings_aug_2025
WHERE is_analysis_ready = TRUE
GROUP BY clean_manufacturing_year
ORDER BY clean_manufacturing_year;


/*
===============================================================================
Q2. Listed price by mileage category
===============================================================================
*/

WITH mileage_segments AS (
    SELECT
        CASE
            WHEN clean_mileage_km < 50000 THEN 'Low mileage'
            WHEN clean_mileage_km >= 50000 AND clean_mileage_km < 150000 THEN 'Moderate mileage'
            ELSE 'High mileage'
        END AS mileage_category,
        CASE
            /* Enforce report ordering with our desired business order. */
            WHEN clean_mileage_km < 50000 THEN 1
            WHEN clean_mileage_km >= 50000 AND clean_mileage_km < 150000 THEN 2
            ELSE 3
        END AS mileage_category_order,
        clean_price_egp,
        clean_mileage_km,
        clean_manufacturing_year
    FROM clean.clean_used_car_listings_aug_2025
    WHERE is_analysis_ready = TRUE
)

SELECT
    mileage_category,
    COUNT(*) AS number_of_listings,
    MIN(clean_price_egp) AS minimum_listed_price,
    TRUNC(AVG(clean_price_egp)) AS average_listed_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp) AS median_listed_price,
    MAX(clean_price_egp) AS maximum_listed_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_mileage_km) AS median_mileage_km,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_manufacturing_year) AS median_manufacturing_year
FROM mileage_segments
GROUP BY mileage_category, mileage_category_order
ORDER BY mileage_category_order;


/*
===============================================================================
Q3. Budget segment summary
===============================================================================
*/

WITH budget_segments AS (
    SELECT
        source_company,
        source_model,
        clean_price_egp,
        clean_mileage_km,
        clean_manufacturing_year,
        CASE
            WHEN clean_price_egp < 300000 THEN 'Very low budget'
            WHEN clean_price_egp >= 300000 AND clean_price_egp < 600000 THEN 'Low budget'
            WHEN clean_price_egp >= 600000 AND clean_price_egp < 1000000 THEN 'Mid budget'
            WHEN clean_price_egp >= 1000000 AND clean_price_egp < 2000000 THEN 'High budget'
            ELSE 'Premium budget'
        END AS budget_segment,
        CASE
            WHEN clean_price_egp < 300000 THEN 1
            WHEN clean_price_egp >= 300000 AND clean_price_egp < 600000 THEN 2
            WHEN clean_price_egp >= 600000 AND clean_price_egp < 1000000 THEN 3
            WHEN clean_price_egp >= 1000000 AND clean_price_egp < 2000000 THEN 4
            ELSE 5
        END AS budget_segment_order
    FROM clean.clean_used_car_listings_aug_2025
    WHERE is_analysis_ready = TRUE
)

SELECT
    budget_segment,
    COUNT(*) AS number_of_listings,
    MIN(clean_price_egp) AS minimum_listed_price,
    TRUNC(AVG(clean_price_egp)) AS average_listed_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp) AS median_listed_price,
    MAX(clean_price_egp) AS maximum_listed_price,
    ROUND(
        ((MAX(clean_price_egp) - PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp))
        * 100.0 / PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp))::NUMERIC,
        2
    ) AS upside_from_median_pct,
    ROUND(
        ((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp) - MIN(clean_price_egp))
        * 100.0 / PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp))::NUMERIC,
        2
    ) AS downside_from_median_pct,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_mileage_km) AS median_mileage_km,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_manufacturing_year) AS median_manufacturing_year
FROM budget_segments
GROUP BY budget_segment, budget_segment_order
ORDER BY budget_segment_order;


/*
===============================================================================
Q3B. Top company/model combinations within each budget segment
===============================================================================
*/

WITH budget_segments AS (
    SELECT
        source_company,
        source_model,
        clean_price_egp,
        clean_mileage_km,
        clean_manufacturing_year,
        CASE
            WHEN clean_price_egp < 300000 THEN 'Very low budget'
            WHEN clean_price_egp >= 300000 AND clean_price_egp < 600000 THEN 'Low budget'
            WHEN clean_price_egp >= 600000 AND clean_price_egp < 1000000 THEN 'Mid budget'
            WHEN clean_price_egp >= 1000000 AND clean_price_egp < 2000000 THEN 'High budget'
            ELSE 'Premium budget'
        END AS budget_segment,
        CASE
            WHEN clean_price_egp < 300000 THEN 1
            WHEN clean_price_egp >= 300000 AND clean_price_egp < 600000 THEN 2
            WHEN clean_price_egp >= 600000 AND clean_price_egp < 1000000 THEN 3
            WHEN clean_price_egp >= 1000000 AND clean_price_egp < 2000000 THEN 4
            ELSE 5
        END AS budget_segment_order
    FROM clean.clean_used_car_listings_aug_2025
    WHERE is_analysis_ready = TRUE
),
company_model_summary AS (
    SELECT
        budget_segment,
        budget_segment_order,
        source_company,
        source_model,
        COUNT(*) AS number_of_listings,
        MIN(clean_price_egp) AS minimum_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp) AS median_listed_price,
        MAX(clean_price_egp) AS maximum_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_mileage_km) AS median_mileage_km,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_manufacturing_year) AS median_manufacturing_year
    FROM budget_segments
    GROUP BY budget_segment, budget_segment_order, source_company, source_model
),
ranked_models AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY budget_segment
            ORDER BY number_of_listings DESC, source_company, source_model
        ) AS rank_in_budget_segment
    FROM company_model_summary
)

SELECT
    budget_segment,
    source_company AS company,
    source_model AS model,
    number_of_listings,
    minimum_listed_price,
    median_listed_price,
    maximum_listed_price,
    median_mileage_km,
    median_manufacturing_year,
    rank_in_budget_segment
FROM ranked_models
WHERE rank_in_budget_segment <= 5
ORDER BY budget_segment_order, rank_in_budget_segment;


/*
===============================================================================
Q4. Seller benchmark by similar company, model, year, and mileage category
===============================================================================
*/

WITH similar_car_benchmarks_step1 AS (
    SELECT
        source_company,
        source_model,
        clean_manufacturing_year,
        CASE
            WHEN clean_mileage_km < 50000 THEN 'Low mileage'
            WHEN clean_mileage_km >= 50000 AND clean_mileage_km < 150000 THEN 'Moderate mileage'
            ELSE 'High mileage'
        END AS mileage_category,
        COUNT(*) AS number_of_similar_listings,
        MIN(clean_price_egp) AS minimum_listed_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY clean_price_egp) AS q1_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp) AS median_listed_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY clean_price_egp) AS q3_listed_price,
        MAX(clean_price_egp) AS maximum_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_mileage_km) AS median_mileage_km
    FROM clean.clean_used_car_listings_aug_2025
    WHERE is_analysis_ready = TRUE
    GROUP BY source_company, source_model, clean_manufacturing_year, mileage_category
    HAVING COUNT(*) >= 5
),
similar_car_benchmarks_step2 AS (
    SELECT
        *,
        q3_listed_price - q1_listed_price AS iqr_listed_price
    FROM similar_car_benchmarks_step1
),
similar_car_benchmarks_final AS (
    SELECT
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        minimum_listed_price,
        q1_listed_price,
        median_listed_price,
        q3_listed_price,
        maximum_listed_price,
        q1_listed_price - (1.5 * iqr_listed_price) AS lower_outlier_boundary,
        q3_listed_price + (1.5 * iqr_listed_price) AS upper_outlier_boundary,
        median_mileage_km
    FROM similar_car_benchmarks_step2
)

SELECT
    source_company AS company,
    source_model AS model,
    clean_manufacturing_year AS manufacturing_year,
    mileage_category,
    number_of_similar_listings,

    /* Cap the lower boundary at the observed minimum price for practical interpretation. */
    GREATEST(minimum_listed_price, lower_outlier_boundary) AS lower_price_boundary,

    q1_listed_price,
    median_listed_price,
    q3_listed_price,

    /* Cap the upper boundary at the observed maximum price for practical interpretation. */
    LEAST(maximum_listed_price, upper_outlier_boundary) AS upper_price_boundary,

    median_mileage_km
FROM similar_car_benchmarks_final
WHERE
    source_company = 'Nissan'
    AND source_model = 'Sunny'
    AND clean_manufacturing_year = 2014
    AND mileage_category = 'Moderate mileage';


/*
===============================================================================
Q5. Seller pricing guide by urgency and price position
===============================================================================
*/

WITH similar_car_benchmarks_step1 AS (
    SELECT
        source_company,
        source_model,
        clean_manufacturing_year,
        CASE
            WHEN clean_mileage_km < 50000 THEN 'Low mileage'
            WHEN clean_mileage_km >= 50000 AND clean_mileage_km < 150000 THEN 'Moderate mileage'
            ELSE 'High mileage'
        END AS mileage_category,
        COUNT(*) AS number_of_similar_listings,
        MIN(clean_price_egp) AS minimum_listed_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY clean_price_egp) AS q1_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_price_egp) AS median_listed_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY clean_price_egp) AS q3_listed_price,
        MAX(clean_price_egp) AS maximum_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY clean_mileage_km) AS median_mileage_km
    FROM clean.clean_used_car_listings_aug_2025
    WHERE is_analysis_ready = TRUE
    GROUP BY source_company, source_model, clean_manufacturing_year, mileage_category
    HAVING COUNT(*) >= 5
),
similar_car_benchmarks_step2 AS (
    SELECT
        *,
        q3_listed_price - q1_listed_price AS iqr_listed_price
    FROM similar_car_benchmarks_step1
),
similar_car_benchmarks_final AS (
    SELECT
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        minimum_listed_price,
        q1_listed_price,
        median_listed_price,
        q3_listed_price,
        maximum_listed_price,
        q1_listed_price - (1.5 * iqr_listed_price) AS lower_outlier_boundary,
        q3_listed_price + (1.5 * iqr_listed_price) AS upper_outlier_boundary,
        median_mileage_km
    FROM similar_car_benchmarks_step2
),
pricing_guide AS (
    SELECT
        1 AS pricing_order,
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        'Unusually low pricing' AS pricing_position,
        minimum_listed_price AS price_from,
        lower_outlier_boundary AS price_to,
        'Very aggressive pricing; may signal urgent sale or possible listing issue' AS seller_strategy,
        'Statistically unusual low price; inspect condition, documents, mileage, and listing accuracy carefully' AS buyer_interpretation
    FROM similar_car_benchmarks_final
    WHERE minimum_listed_price < lower_outlier_boundary

    UNION ALL

    SELECT
        2 AS pricing_order,
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        'Aggressive / urgent pricing',
        GREATEST(minimum_listed_price, lower_outlier_boundary),
        q1_listed_price,
        'Faster-sale range',
        'Attractive, but inspect carefully'
    FROM similar_car_benchmarks_final

    UNION ALL

    SELECT
        3 AS pricing_order,
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        'Competitive-normal pricing',
        q1_listed_price,
        median_listed_price,
        'Normal competitive range',
        'Within normal benchmark'
    FROM similar_car_benchmarks_final

    UNION ALL

    SELECT
        4 AS pricing_order,
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        'Typical benchmark pricing',
        median_listed_price,
        median_listed_price,
        'Typical market reference',
        'Around the median'
    FROM similar_car_benchmarks_final

    UNION ALL

    SELECT
        5 AS pricing_order,
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        'Upper-normal pricing',
        median_listed_price,
        q3_listed_price,
        'Good for seller not in hurry',
        'Still normal but higher'
    FROM similar_car_benchmarks_final

    UNION ALL

    SELECT
        6 AS pricing_order,
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        'Premium / patient pricing',
        q3_listed_price,
        LEAST(maximum_listed_price, upper_outlier_boundary),
        'Needs justification',
        'Buyer should check why price is high'
    FROM similar_car_benchmarks_final

    UNION ALL

    SELECT
        7 AS pricing_order,
        source_company,
        source_model,
        clean_manufacturing_year,
        mileage_category,
        number_of_similar_listings,
        'Unusually high pricing',
        upper_outlier_boundary,
        maximum_listed_price,
        'Strong justification required',
        'Statistically unusual high price'
    FROM similar_car_benchmarks_final
    WHERE maximum_listed_price > upper_outlier_boundary
)

SELECT
    source_company AS company,
    source_model AS model,
    clean_manufacturing_year AS manufacturing_year,
    mileage_category,
    number_of_similar_listings,
    pricing_position,
    price_from,
    price_to,
    seller_strategy,
    buyer_interpretation
FROM pricing_guide
WHERE
    source_company = 'Nissan'
    AND source_model = 'Sunny'
    AND clean_manufacturing_year = 2013
    AND mileage_category = 'High mileage'
ORDER BY pricing_order;
