# Star Schema Design

## Purpose

This document explains the reporting model created after the clean SQL analysis phase.

The goal of the star schema is to prepare the project for reporting and future Power BI dashboarding while keeping the model aligned with the project business questions.

## Business Questions Supported

1. How do manufacturing year and mileage category relate to listed-price benchmarks?
2. Which company/model combinations are common in each budget segment?
3. What is a fair listed-price benchmark for a selected car?
4. Which features are common for selected comparable listings?
5. How do listing counts and price benchmarks differ by location?

## Analysis Schema Tables

The final reporting model is stored in the `analysis` schema.

```text
analysis.bridge_listing_feature
analysis.dim_budget_segment
analysis.dim_color
analysis.dim_company
analysis.dim_feature
analysis.dim_location
analysis.dim_manufacturing_year
analysis.dim_mileage_category
analysis.dim_model
analysis.fact_listed_car
```

## Fact Table Grain

```text
One row in analysis.fact_listed_car represents one analysis-ready used-car listing from the clean table.
```

This grain is important because price, mileage, company, model, location, budget segment, and mileage category are analyzed at the individual listing level.

## Main Fact Table

```text
analysis.fact_listed_car
```

Main fact fields:

| Field | Meaning |
|---|---|
| `raw_listing_id` | Listing-level key and traceability link back to the clean layer |
| `company_id` | Foreign key to `dim_company` |
| `model_id` | Foreign key to `dim_model` |
| `manufacturing_year_id` | Foreign key to `dim_manufacturing_year` |
| `color_id` | Foreign key to `dim_color` |
| `location_id` | Foreign key to `dim_location` |
| `mileage_category_id` | Foreign key to `dim_mileage_category` |
| `budget_segment_id` | Foreign key to `dim_budget_segment` |
| `mileage_km` | Clean mileage value in kilometers |
| `price_egp` | Clean listed asking price in EGP |

Typical measures:

| Measure | Calculation / Meaning |
|---|---|
| Listing count | `COUNT(*)` from `fact_listed_car` |
| Median listed price | Median of `price_egp` |
| Average listed price | Average of `price_egp` |
| Minimum / maximum listed price | Range of `price_egp` |
| Median mileage | Median of `mileage_km` |

## Dimensions

| Dimension | Purpose |
|---|---|
| `dim_company` | Supports filtering and grouping by car company/brand |
| `dim_model` | Supports filtering and grouping by listed model |
| `dim_manufacturing_year` | Supports year-based price and availability analysis |
| `dim_color` | Supports color filtering and descriptive analysis |
| `dim_location` | Supports location-based listing and price analysis |
| `dim_budget_segment` | Groups listings into buyer-friendly price ranges |
| `dim_mileage_category` | Groups listings into mileage bands |
| `dim_feature` | Stores individual feature values extracted from the source feature list |

## Company and Model Design Decision

The model uses separate `dim_company` and `dim_model` dimensions.

This matches the source structure and keeps company and model reusable as independent filters. Business questions that require complete market options, such as Toyota Corolla or Nissan Sunny, are answered by joining both dimensions through `analysis.fact_listed_car`.

```text
fact_listed_car
→ dim_company
→ dim_model
```

This design supports company-only analysis, model-only analysis, and combined company/model analysis without adding another dimension table.

## Budget Segment Dimension

`dim_budget_segment` stores fixed business-rule ranges used to make buyer analysis easier.

| Segment | Purpose |
|---|---|
| Very low budget | Entry-level listings |
| Low budget | Affordable common listings |
| Mid budget | Middle-market options |
| High budget | Higher-price listings |
| Premium budget | Expensive and premium listings |

The lower and upper boundaries are stored in the dimension table so the segmentation logic is visible and reusable.

## Mileage Category Dimension

`dim_mileage_category` stores fixed business-rule ranges used to group listings by mileage level.

| Category | Purpose |
|---|---|
| Low mileage | Lower-used listings |
| Moderate mileage | Middle-mileage listings |
| High mileage | Higher-mileage listings |

The category order column supports clean sorting in reports and dashboards.

## Feature Bridge Table

The source `features` column is a pipe-separated list, for example:

```text
Automatic | Air Conditioner | Remote Control
```

One listing can have many features, and one feature can appear in many listings.

Therefore, feature analysis requires a bridge table:

```text
analysis.bridge_listing_feature
```

Bridge table grain:

```text
One row represents one feature assigned to one listing.
```

Relationship pattern:

```text
fact_listed_car
→ bridge_listing_feature
→ dim_feature
```

This allows feature analysis without duplicating rows in the main fact table.

## Validation Checks

The star schema is validated with checks for:

| Check | Purpose |
|---|---|
| Fact row count | Confirms `fact_listed_car` matches analysis-ready clean rows |
| Foreign-key completeness | Confirms fact rows successfully match all dimensions |
| Dimension primary-key uniqueness | Confirms dimension keys are unique |
| Bridge table validation | Confirms feature relationships are loaded correctly |

The fact table contains the same number of rows as the analysis-ready clean layer: **22,423 listings**.

## Modeling Value

The star schema turns the clean table into a reporting-ready structure.

It supports:

- reusable dimensions,
- consistent filters,
- seller benchmark analysis,
- buyer budget-segment analysis,
- location-based analysis,
- feature-level analysis through a bridge table,
- future Power BI dashboard development.

## Limitations

The model still depends on source-listed company, model, location, and feature values. Deeper standardization of trims, variants, and feature names could improve a future version, but it is outside the current project scope.

The project analyzes listed asking prices, not confirmed sold prices. Therefore, the benchmarks should be interpreted as listing-market benchmarks rather than final transaction values.
