/*
===============================================================================
Project: Egypt Used Cars Market Analysis
Script: 09_star_schema_analysis_questions.sql
Purpose: Validate and query the analysis/star schema layer
Database: egypt_used_cars_db
Schema: analysis
===============================================================================

Main fact table:
    analysis.fact_listed_car

Fact table grain:
    One row per analysis-ready used-car listing.

Important limitation:
    Benchmarks are based on listed asking prices, not confirmed sold prices.
===============================================================================
*/


/*
===============================================================================
0. Star Schema Validation Checks
===============================================================================
*/


/*
-------------------------------------------------------------------------------
0.1 Fact row count should match analysis-ready clean rows
Expected result:
- fact_listed_car = 22,423
- analysis_ready_clean_rows = 22,423
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
0.2 Check for null foreign keys in fact_listed_car
Expected result:
- rows_with_null_foreign_key = 0
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS rows_with_null_foreign_key
FROM analysis.fact_listed_car
WHERE raw_listing_id IS NULL
   OR company_id IS NULL
   OR model_id IS NULL
   OR manufacturing_year_id IS NULL
   OR color_id IS NULL
   OR location_id IS NULL
   OR mileage_category_id IS NULL
   OR budget_segment_id IS NULL;


/*
-------------------------------------------------------------------------------
0.3 Confirm dimension primary-key uniqueness
For each dimension, total_rows should equal distinct_key_count.
-------------------------------------------------------------------------------
*/

SELECT
    'dim_budget_segment' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT budget_segment_id) AS distinct_key_count
FROM analysis.dim_budget_segment

UNION ALL

SELECT
    'dim_color' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT color_id) AS distinct_key_count
FROM analysis.dim_color

UNION ALL

SELECT
    'dim_company' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT company_id) AS distinct_key_count
FROM analysis.dim_company

UNION ALL

SELECT
    'dim_feature' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT feature_id) AS distinct_key_count
FROM analysis.dim_feature

UNION ALL

SELECT
    'dim_location' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT location_id) AS distinct_key_count
FROM analysis.dim_location

UNION ALL

SELECT
    'dim_manufacturing_year' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT manufacturing_year_id) AS distinct_key_count
FROM analysis.dim_manufacturing_year

UNION ALL

SELECT
    'dim_mileage_category' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT mileage_category_id) AS distinct_key_count
FROM analysis.dim_mileage_category

UNION ALL

SELECT
    'dim_model' AS dimension_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT model_id) AS distinct_key_count
FROM analysis.dim_model
ORDER BY dimension_name;


/*
-------------------------------------------------------------------------------
0.4 Bridge table validation
bridge_rows should be greater than or equal to listings_with_features.
-------------------------------------------------------------------------------
*/

SELECT
    COUNT(*) AS bridge_rows,
    COUNT(DISTINCT raw_listing_id) AS listings_with_features,
    COUNT(DISTINCT feature_id) AS unique_features_used
FROM analysis.bridge_listing_feature;


/*
===============================================================================
Q1. Manufacturing year and mileage category listed-price benchmarks
===============================================================================

Question:
How do manufacturing year and mileage category relate to listed-price benchmarks?

Audience:
Buyer and seller

Purpose:
Help buyers understand realistic listed-price levels by manufacturing year and
mileage category, and help sellers benchmark asking prices against similar
year/mileage groups.

Note:
Groups with fewer than 5 listings are excluded from the official benchmark
output to avoid weak comparisons based on very small sample sizes.
===============================================================================
*/

SELECT
    my.manufacturing_year,
    mc.mileage_category,
    COUNT(*) AS number_of_listings,
    MIN(ft.price_egp) AS minimum_listed_price,
    TRUNC(AVG(ft.price_egp)) AS average_listed_price,
    ROUND(
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.price_egp))::NUMERIC,
        0
    ) AS median_listed_price,
    MAX(ft.price_egp) AS maximum_listed_price,

    MAX(ft.price_egp) - MIN(ft.price_egp) AS listed_price_gap,

    ROUND(
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.mileage_km))::NUMERIC,
        0
    ) AS median_mileage_km

FROM analysis.fact_listed_car AS ft

INNER JOIN analysis.dim_manufacturing_year AS my
    ON ft.manufacturing_year_id = my.manufacturing_year_id

INNER JOIN analysis.dim_mileage_category AS mc
    ON ft.mileage_category_id = mc.mileage_category_id

GROUP BY
    my.manufacturing_year,
    mc.mileage_category,
    mc.mileage_category_order

HAVING COUNT(*) >= 5

ORDER BY
    my.manufacturing_year ASC,
    mc.mileage_category_order ASC;


/*
===============================================================================
Q2. Common company/model combinations by budget segment
===============================================================================

Question:
Which company/model combinations are common in each budget segment?

Audience:
Buyer and seller

Purpose:
Help buyers identify realistic options within each budget segment and help
sellers understand common competing models in the same budget range.

Business logic:
- Ranking is based first on listing count.
- If listing counts are tied, lower median listed price is ranked first.
- The result returns the top 5 company/model combinations per budget segment.
===============================================================================
*/

WITH company_model_summary AS (
    SELECT
        bs.budget_segment,
        bs.budget_segment_order,
        c.company_name,
        m.model_name,
        COUNT(*) AS number_of_listings,
        MIN(ft.price_egp) AS minimum_listed_price,
        TRUNC(AVG(ft.price_egp)) AS average_listed_price,
        ROUND(
            (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.price_egp))::NUMERIC,
            0
        ) AS median_listed_price,
        MAX(ft.price_egp) AS maximum_listed_price,
        ROUND(
            (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.mileage_km))::NUMERIC,
            0
        ) AS median_mileage_km,
        ROUND(
            (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY my.manufacturing_year))::NUMERIC,
            0
        ) AS median_manufacturing_year

    FROM analysis.fact_listed_car AS ft

    INNER JOIN analysis.dim_company AS c
        ON ft.company_id = c.company_id

    INNER JOIN analysis.dim_model AS m
        ON ft.model_id = m.model_id

    INNER JOIN analysis.dim_budget_segment AS bs
        ON ft.budget_segment_id = bs.budget_segment_id

    INNER JOIN analysis.dim_manufacturing_year AS my
        ON ft.manufacturing_year_id = my.manufacturing_year_id

    GROUP BY
        bs.budget_segment,
        bs.budget_segment_order,
        c.company_name,
        m.model_name

    HAVING COUNT(*) >= 5
),

ranked_company_models AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY budget_segment
            ORDER BY
                number_of_listings DESC,
                median_listed_price ASC,
                company_name ASC,
                model_name ASC
        ) AS rank_in_budget_segment

    FROM company_model_summary
)

SELECT
    budget_segment,
    company_name,
    model_name,
    number_of_listings,
    minimum_listed_price,
    average_listed_price,
    median_listed_price,
    maximum_listed_price,
    median_mileage_km,
    median_manufacturing_year

FROM ranked_company_models

WHERE rank_in_budget_segment <= 5

ORDER BY
    budget_segment_order ASC,
    rank_in_budget_segment ASC;


/*
===============================================================================
Q3. Selected-car listed-price benchmark and buyer/seller pricing guide
===============================================================================

Question:
What is a fair listed-price benchmark for a specific car, and how can that
benchmark guide buyer/seller pricing decisions?

Audience:
Buyer and seller

Purpose:
Help buyers evaluate whether a listing is within a normal comparable range and
help sellers estimate a reasonable asking price based on similar listings.

Selected comparable group:
Nissan Sunny, 2014, Moderate mileage

Q3 has two outputs:
- Q3A: Benchmark summary for the selected comparable group.
- Q3B: Buyer/seller pricing guide using the benchmark zones.
===============================================================================
*/


/*
-------------------------------------------------------------------------------
Q3A. Selected-car listed-price benchmark summary
-------------------------------------------------------------------------------
*/

WITH similar_car_benchmarks AS (
    SELECT
        c.company_name,
        m.model_name,
        my.manufacturing_year,
        mc.mileage_category,
        COUNT(*) AS number_of_listings,
        MIN(ft.price_egp) AS minimum_listed_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ft.price_egp) AS q1_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.price_egp) AS median_listed_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ft.price_egp) AS q3_listed_price,
        MAX(ft.price_egp) AS maximum_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.mileage_km) AS median_mileage_km

    FROM analysis.fact_listed_car AS ft

    INNER JOIN analysis.dim_company AS c
        ON ft.company_id = c.company_id

    INNER JOIN analysis.dim_model AS m
        ON ft.model_id = m.model_id

    INNER JOIN analysis.dim_manufacturing_year AS my
        ON ft.manufacturing_year_id = my.manufacturing_year_id

    INNER JOIN analysis.dim_mileage_category AS mc
        ON ft.mileage_category_id = mc.mileage_category_id

    GROUP BY
        c.company_name,
        m.model_name,
        my.manufacturing_year,
        mc.mileage_category

    HAVING COUNT(*) >= 5
),

benchmark_boundaries AS (
    SELECT
        *,
        q3_listed_price - q1_listed_price AS iqr_listed_price,
        q1_listed_price - (1.5 * (q3_listed_price - q1_listed_price)) AS lower_outlier_boundary,
        q3_listed_price + (1.5 * (q3_listed_price - q1_listed_price)) AS upper_outlier_boundary

    FROM similar_car_benchmarks
)

SELECT
    company_name,
    model_name,
    manufacturing_year,
    mileage_category,
    number_of_listings,

    ROUND(minimum_listed_price::NUMERIC, 0) AS minimum_listed_price,
    ROUND(q1_listed_price::NUMERIC, 0) AS q1_listed_price,
    ROUND(median_listed_price::NUMERIC, 0) AS median_listed_price,
    ROUND(q3_listed_price::NUMERIC, 0) AS q3_listed_price,
    ROUND(maximum_listed_price::NUMERIC, 0) AS maximum_listed_price,

    ROUND(
        GREATEST(minimum_listed_price, lower_outlier_boundary)::NUMERIC,
        0
    ) AS lower_price_boundary,

    ROUND(
        LEAST(maximum_listed_price, upper_outlier_boundary)::NUMERIC,
        0
    ) AS upper_price_boundary,

    ROUND(median_mileage_km::NUMERIC, 0) AS median_mileage_km

FROM benchmark_boundaries

WHERE company_name = 'Nissan'
  AND model_name = 'Sunny'
  AND manufacturing_year = 2014
  AND mileage_category = 'Moderate mileage';


/*
-------------------------------------------------------------------------------
Q3B. Buyer/seller pricing guide for the selected benchmark
-------------------------------------------------------------------------------
*/

WITH similar_car_benchmarks AS (
    SELECT
        c.company_name,
        m.model_name,
        my.manufacturing_year,
        mc.mileage_category,
        COUNT(*) AS number_of_listings,
        MIN(ft.price_egp) AS minimum_listed_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ft.price_egp) AS q1_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.price_egp) AS median_listed_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ft.price_egp) AS q3_listed_price,
        MAX(ft.price_egp) AS maximum_listed_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.mileage_km) AS median_mileage_km

    FROM analysis.fact_listed_car AS ft

    INNER JOIN analysis.dim_company AS c
        ON ft.company_id = c.company_id

    INNER JOIN analysis.dim_model AS m
        ON ft.model_id = m.model_id

    INNER JOIN analysis.dim_manufacturing_year AS my
        ON ft.manufacturing_year_id = my.manufacturing_year_id

    INNER JOIN analysis.dim_mileage_category AS mc
        ON ft.mileage_category_id = mc.mileage_category_id

    GROUP BY
        c.company_name,
        m.model_name,
        my.manufacturing_year,
        mc.mileage_category

    HAVING COUNT(*) >= 5
),

benchmark_boundaries AS (
    SELECT
        *,
        q3_listed_price - q1_listed_price AS iqr_listed_price,
        q1_listed_price - (1.5 * (q3_listed_price - q1_listed_price)) AS lower_outlier_boundary,
        q3_listed_price + (1.5 * (q3_listed_price - q1_listed_price)) AS upper_outlier_boundary

    FROM similar_car_benchmarks
),

pricing_guide AS (
    SELECT
        1 AS pricing_order,
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        number_of_listings,

        'Unusually low pricing' AS pricing_position,
        minimum_listed_price AS price_from,
        lower_outlier_boundary AS price_to,
        'Very aggressive pricing; may indicate urgent sale or a listing issue' AS seller_strategy,
        'Statistically unusual low price; buyer should inspect condition, documents, mileage, and listing accuracy carefully' AS buyer_interpretation

    FROM benchmark_boundaries
    WHERE minimum_listed_price < lower_outlier_boundary

    UNION ALL

    SELECT
        2 AS pricing_order,
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        number_of_listings,

        'Aggressive / urgent pricing' AS pricing_position,
        GREATEST(minimum_listed_price, lower_outlier_boundary) AS price_from,
        q1_listed_price AS price_to,
        'Faster-sale range; useful when the seller prioritizes speed over maximum asking price' AS seller_strategy,
        'Attractive relative to similar listings, but buyer should still verify condition and listing accuracy' AS buyer_interpretation

    FROM benchmark_boundaries

    UNION ALL

    SELECT
        3 AS pricing_order,
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        number_of_listings,

        'Competitive-normal pricing' AS pricing_position,
        q1_listed_price AS price_from,
        median_listed_price AS price_to,
        'Normal competitive range below or around the benchmark median' AS seller_strategy,
        'Within the normal comparable range; generally reasonable if condition matches the listing' AS buyer_interpretation

    FROM benchmark_boundaries

    UNION ALL

    SELECT
        4 AS pricing_order,
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        number_of_listings,

        'Typical benchmark pricing' AS pricing_position,
        median_listed_price AS price_from,
        median_listed_price AS price_to,
        'Central listed-price benchmark for similar listings' AS seller_strategy,
        'Around the median of comparable listed cars' AS buyer_interpretation

    FROM benchmark_boundaries

    UNION ALL

    SELECT
        5 AS pricing_order,
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        number_of_listings,

        'Upper-normal pricing' AS pricing_position,
        median_listed_price AS price_from,
        q3_listed_price AS price_to,
        'Higher but still normal range; seller should justify with condition, maintenance, trim, or features' AS seller_strategy,
        'Still within the normal comparable range, but buyer should check justification for the higher price' AS buyer_interpretation

    FROM benchmark_boundaries

    UNION ALL

    SELECT
        6 AS pricing_order,
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        number_of_listings,

        'Premium / patient pricing' AS pricing_position,
        q3_listed_price AS price_from,
        LEAST(maximum_listed_price, upper_outlier_boundary) AS price_to,
        'Premium asking range; better suited for sellers who can wait and have strong justification' AS seller_strategy,
        'High relative to similar listings; buyer should compare condition, mileage, features, and alternatives carefully' AS buyer_interpretation

    FROM benchmark_boundaries

    UNION ALL

    SELECT
        7 AS pricing_order,
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        number_of_listings,

        'Unusually high pricing' AS pricing_position,
        upper_outlier_boundary AS price_from,
        maximum_listed_price AS price_to,
        'Statistically unusual high range; strong justification is required' AS seller_strategy,
        'Statistically unusual high price compared with similar listings' AS buyer_interpretation

    FROM benchmark_boundaries
    WHERE maximum_listed_price > upper_outlier_boundary
)

SELECT
    company_name,
    model_name,
    manufacturing_year,
    mileage_category,
    number_of_listings,

    pricing_position,
    ROUND(price_from::NUMERIC, 0) AS price_from,
    ROUND(price_to::NUMERIC, 0) AS price_to,
    seller_strategy,
    buyer_interpretation

FROM pricing_guide

WHERE company_name = 'Nissan'
  AND model_name = 'Sunny'
  AND manufacturing_year = 2014
  AND mileage_category = 'Moderate mileage'

ORDER BY pricing_order;

/*
===============================================================================
Q4. Common features and listed-price benchmarks for selected comparable listings
===============================================================================

Question:
For a selected company/model/year/mileage group,
which features are common and what are their listed-price benchmarks?

Audience:
Buyer

Purpose:
Help buyers compare commonly listed features within a selected comparable car
group and understand how listed-price benchmarks differ by feature.

Selected comparable group:
Nissan Sunny, 2014, Moderate mileage

===============================================================================
*/

WITH summary AS (
    SELECT
        dc.company_name,
        dm.model_name,
        dmy.manufacturing_year,
        dmc.mileage_category,
        df.feature_name,
        COUNT(*) AS feature_listing_count,
        TRUNC(MIN(fls.price_egp)) AS min_listed_price,
        TRUNC(AVG(fls.price_egp)) AS avg_listed_price,
        TRUNC(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fls.price_egp)) AS median_listed_price,
        TRUNC(MAX(fls.price_egp)) AS max_listed_price

    FROM analysis.fact_listed_car AS fls

    INNER JOIN analysis.dim_company AS dc
        USING (company_id)

    INNER JOIN analysis.dim_model AS dm
        USING (model_id)

    INNER JOIN analysis.dim_manufacturing_year AS dmy
        USING (manufacturing_year_id)

    INNER JOIN analysis.dim_mileage_category AS dmc
        USING (mileage_category_id)

    INNER JOIN analysis.bridge_listing_feature AS blf
        ON fls.raw_listing_id = blf.raw_listing_id

    INNER JOIN analysis.dim_feature AS df
        ON blf.feature_id = df.feature_id

    GROUP BY
        dc.company_name,
        dm.model_name,
        dmy.manufacturing_year,
        dmc.mileage_category,
        df.feature_name
),

given_car AS (
    SELECT
        company_name,
        model_name,
        manufacturing_year,
        mileage_category,
        feature_name,
        feature_listing_count,
        min_listed_price,
        avg_listed_price,
        median_listed_price,
        max_listed_price

    FROM summary

    WHERE company_name = 'Nissan'
      AND model_name = 'Sunny'
      AND manufacturing_year = 2014
      AND mileage_category = 'Moderate mileage'
),

total_listing AS (
    SELECT
        dc.company_name,
        dm.model_name,
        dmy.manufacturing_year,
        dmc.mileage_category,
        COUNT(*) AS count_listing_car

    FROM analysis.fact_listed_car AS fls

    INNER JOIN analysis.dim_company AS dc
        USING (company_id)

    INNER JOIN analysis.dim_model AS dm
        USING (model_id)

    INNER JOIN analysis.dim_manufacturing_year AS dmy
        USING (manufacturing_year_id)

    INNER JOIN analysis.dim_mileage_category AS dmc
        USING (mileage_category_id)

    WHERE dc.company_name = 'Nissan'
      AND dm.model_name = 'Sunny'
      AND dmy.manufacturing_year = 2014
      AND dmc.mileage_category = 'Moderate mileage'

    GROUP BY
        dc.company_name,
        dm.model_name,
        dmy.manufacturing_year,
        dmc.mileage_category
)

SELECT
	company_name,
	model_name,
	manufacturing_year,
	mileage_category,
	feature_name,
	feature_listing_count,
	min_listed_price,
	avg_listed_price,
	median_listed_price,
	max_listed_price,
	ROUND(feature_listing_count * 100.0 / (SELECT count_listing_car FROM total_listing),2) AS feature_share_percent

FROM given_car

ORDER BY
    feature_listing_count DESC,
    feature_name ASC;


/*
===============================================================================
Q5. Location listing counts and listed-price benchmarks
===============================================================================

Question:
How do listing counts and listed-price benchmarks differ by location?

Audience:
Buyer and seller

Purpose:
Help buyers and sellers understand how listing availability, listed-price
benchmarks, mileage, and vehicle age differ across locations.

Note:
Locations with fewer than 20 listings are excluded from the official benchmark
output to avoid weak comparisons based on small sample sizes.
===============================================================================
*/

SELECT
    l.location_name,
    COUNT(*) AS number_of_listings,
    MIN(ft.price_egp) AS minimum_listed_price,
    ROUND(AVG(ft.price_egp), 0) AS average_listed_price,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.price_egp))::NUMERIC, 0) AS median_listed_price,
    MAX(ft.price_egp) AS maximum_listed_price,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ft.mileage_km))::NUMERIC, 0) AS median_mileage_km
FROM analysis.fact_listed_car AS ft
INNER JOIN analysis.dim_location AS l
    ON ft.location_id = l.location_id
GROUP BY l.location_name
HAVING COUNT(*) >= 50
ORDER BY number_of_listings DESC, l.location_name;