# Power BI Report Design

## Purpose

This document summarizes the Power BI reporting layer for the Egypt Used Cars Market Analysis project.

The report turns the validated PostgreSQL analytical model into interactive buyer and seller views for market exploration, budget-based filtering, comparable-car benchmarking, and asking-price evaluation.

## Data Connection

Power BI Desktop connects directly to PostgreSQL in **Import Mode** and loads the reporting tables from the `analysis` schema.

```text
PostgreSQL analysis schema
→ Direct PostgreSQL connection — Import Mode
→ Power BI semantic model
→ Interactive report
```

CSV exports are not used as an intermediate reporting source.

## Semantic Model

The Power BI semantic model is built on the reporting-ready star schema in PostgreSQL.

### Main Fact Table

```text
analysis.fact_listed_car
```

Grain:

```text
One row represents one analysis-ready used-car listing.
```

### Dimensions

| Table | Purpose |
|---|---|
| `analysis.dim_company` | Company filtering and aggregation |
| `analysis.dim_model` | Model filtering and aggregation |
| `analysis.dim_manufacturing_year` | Manufacturing-year analysis |
| `analysis.dim_color` | Color filtering |
| `analysis.dim_location` | Location analysis |
| `analysis.dim_mileage_category` | Mileage-segment analysis |
| `analysis.dim_budget_segment` | Budget-segment analysis |
| `analysis.dim_feature` | Feature-level analysis |

### Feature Bridge Table

```text
analysis.bridge_listing_feature
```

The source feature field contains multiple values per listing. The bridge table supports feature-level analysis while preserving the listing grain of the main fact table.

## Report Pages

### 1. Market Overview

Provides a high-level view of the analysis-ready market.

Main outputs:

- Total listings
- Median listed price
- Median mileage
- Median listed price by manufacturing year
- Median listed price by mileage category
- Mileage distribution within budget segments
- Top listed car companies

### 2. Buyer Budget Explorer

Helps buyers explore realistic options within a selected budget.

Main outputs:

- Buyer budget input
- Affordable listings count
- Affordable median listed price
- Gap to buyer budget
- Affordable company/model options
- Top locations for affordable listings
- Common features within the selected budget

### 3. Buyer Car Benchmark

Compares a selected car with similar listings.

Comparable listings are filtered by:

```text
Company
+ Model
+ Manufacturing year
+ Mileage category
```

Main outputs:

- Similar listings count
- Benchmark confidence
- Q1, median, and Q3 listed prices
- Lower and upper practical price boundaries
- Median mileage
- Common features among comparable listings
- Top locations with similar listings

### 4. Listing Price Evaluator

Evaluates a selected asking price against the comparable-car benchmark.

Main outputs:

- Asking-price input
- Selected asking price
- Pricing position
- Buyer interpretation
- Seller strategy

The page reuses the benchmark measures from the Buyer Car Benchmark page rather than calculating a separate benchmark.

## Main DAX Logic

### Core KPI Measures

The model includes reusable measures for:

- Listings count
- Median listed price
- Median mileage
- Affordable listings
- Affordable median listed price

### Comparable-Car Benchmark

The benchmark uses quartiles and IQR-based limits.

```text
Lower practical boundary
= MAX(observed minimum price, lower IQR fence)

Upper practical boundary
= MIN(observed maximum price, upper IQR fence)
```

### Reliable Benchmark Rule

Comparable-car statistics are shown only when:

```text
Complete comparable-car selection
AND
Similar listings count >= 5
```

This prevents weak benchmarks from being presented as reliable market guidance.

### Feature Share

Feature measures use distinct listing counts to avoid overstating results when a listing has multiple features.

### Asking-Price Evaluation

The asking-price evaluator classifies the selected value into pricing zones such as:

- Unusually low pricing
- Aggressive / urgent pricing
- Competitive-normal pricing
- Typical benchmark pricing
- Upper-normal pricing
- Premium / patient pricing
- Unusually high pricing

The selected pricing zone drives the buyer interpretation and seller strategy text.

## Validation Approach

The Power BI report was validated against PostgreSQL outputs before finalizing the reporting layer.

Validation covered:

- Semantic-model relationships
- Market overview KPIs and charts
- Buyer budget explorer KPIs
- Affordable company/model options
- Affordable locations
- Affordable feature counts and shares
- Comparable-car benchmark KPIs
- Comparable feature counts and shares
- Comparable locations

The Listing Price Evaluator was functionally tested across the pricing zones. A separate SQL benchmark query was not required because the page reuses the already validated comparable-car benchmark measures.

Validation evidence is stored in:

```text
power_bi/validation/
```

## Report Files

| File | Purpose |
|---|---|
| `power_bi/egypt_used_cars_market_analysis.pbix` | Power BI source file |
| `power_bi/egypt_used_cars_market_analysis_report.pdf` | Exported report |
| `power_bi/egypt_used_cars_power_bi_theme.json` | Report theme |
| `assets/egypt_used_cars_market_analysis_report_preview.png` | README report preview |

## Limitations

- The analysis uses listed asking prices, not confirmed sale prices.
- The report includes only records marked as analysis-ready in the clean layer.
- Feature insights depend on the completeness and consistency of the source feature field.
- Comparable-car benchmarks with fewer than five listings are not presented as reliable benchmarks.
- Power BI uses Import Mode, so database changes require a data refresh before they appear in the report.
