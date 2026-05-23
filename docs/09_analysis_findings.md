# Analysis Findings

## Purpose

This document summarizes the final SQL analysis findings from the Egypt Used Cars Market Insights project.

The findings are based on the reporting-ready analysis layer:

```sql
analysis.fact_listed_car
```

The fact table contains **22,423 analysis-ready listings**, matching the clean layer records where:

```sql
is_analysis_ready = TRUE
```

> Important limitation: findings are based on listed asking prices, not confirmed sold prices. Results should be interpreted as listing-market benchmarks, not guaranteed market valuations.

## Analysis Model Validation

Before answering the business questions, the analysis star schema was validated.

| Validation Check | Result |
|---|---:|
| Fact table rows | 22,423 |
| Clean analysis-ready rows | 22,423 |
| Rows with null foreign keys in fact table | 0 |
| Dimension primary-key checks | PASS |
| Bridge table rows | 48,828 |
| Listings with at least one feature | 15,667 |
| Unique feature values used | 4 |

The validation confirms that the analysis model preserved the expected analysis-ready listing count, maintained complete fact-to-dimension relationships, and correctly populated the feature bridge table.

---

## 1. Manufacturing Year and Mileage Category Benchmarks

### Question

How do manufacturing year and mileage category relate to listed-price benchmarks?

### Method

Listings were grouped by manufacturing year and mileage category. Groups with fewer than five listings were excluded from the official benchmark output to avoid weak comparisons.

### Result Summary

The query returned **113 reliable year/mileage benchmark groups**.

The output includes:

- listing count,
- minimum listed price,
- average listed price,
- median listed price,
- maximum listed price,
- listed-price gap,
- median mileage.

### Interpretation

Newer vehicles and lower-mileage categories generally show higher listed-price benchmarks. However, listed price is not explained by manufacturing year or mileage alone. Company, model, condition, trim, feature availability, location, and outlier listings also influence price.

The minimum listing threshold improves reliability by preventing very small groups from being treated as strong benchmarks.

---

## 2. Common Company/Model Options by Budget Segment

### Question

Which company/model combinations are common in each budget segment?

### Method

Company/model combinations were ranked within each budget segment by listing count. When listing counts were tied, the lower median listed price was ranked first to support buyer-focused interpretation.

### Result

| Budget Segment | Common Listed Options |
|---|---|
| Very low budget | Daewoo Nubira, Daewoo Lanos, Chevrolet Lanos, Speranza A516, Speranza A113 |
| Low budget | Nissan Sunny, Chevrolet Optra, Renault Logan, Mitsubishi Lancer, Chevrolet Aveo |
| Mid budget | Hyundai Elantra, Mitsubishi Lancer, Chery Tiggo, Fiat Tipo, Toyota Corolla |
| High budget | Kia Sportage, Hyundai Tucson, Toyota Corolla, Mercedes C, Hyundai Elantra |
| Premium budget | Mercedes C, Mercedes E, Skoda Kodiaq, Mercedes GLC, Land Rover |

### Interpretation

Budget analysis becomes more useful when it identifies realistic market options, not only price ranges.

The result helps buyers understand which vehicles are commonly available within each budget segment and helps sellers identify common competing models in the same price range.

---

## 3. Selected-Car Listed-Price Benchmark and Pricing Guide

### Question

What is a fair listed-price benchmark for a selected car, and how can that benchmark guide buyer/seller pricing decisions?

### Selected Comparable Group

```text
Nissan Sunny
2014
Moderate mileage
```

### Benchmark Result

| Metric | Value |
|---|---:|
| Similar listings | 14 |
| Minimum listed price | 400,000 EGP |
| Q1 listed price | 405,000 EGP |
| Median listed price | 452,500 EGP |
| Q3 listed price | 507,500 EGP |
| Maximum listed price | 560,000 EGP |
| Lower price boundary | 400,000 EGP |
| Upper price boundary | 560,000 EGP |
| Median mileage | 113,500 km |

### Pricing Guide

| Pricing Position | Price Range | Interpretation |
|---|---:|---|
| Aggressive / urgent pricing | 400,000–405,000 EGP | Attractive relative to similar listings; buyer should verify condition and listing accuracy. |
| Competitive-normal pricing | 405,000–452,500 EGP | Within the normal comparable range, generally reasonable if condition matches the listing. |
| Typical benchmark pricing | 452,500 EGP | Around the median of comparable listed cars. |
| Upper-normal pricing | 452,500–507,500 EGP | Still within the normal comparable range, but seller should justify the higher price. |
| Premium / patient pricing | 507,500–560,000 EGP | Higher relative to similar listings; buyer should compare condition, mileage, features, and alternatives carefully. |

### Interpretation

For Nissan Sunny 2014 moderate-mileage listings, the median listed benchmark is **452,500 EGP**. The interquartile range from **405,000 to 507,500 EGP** represents the core competitive range for comparable listings.

The pricing guide turns the benchmark into a decision-support view for both buyers and sellers.

---

## 4. Common Features for Selected Comparable Listings

### Question

For a selected company/model/year/mileage group, which features are common and what are their listed-price benchmarks?

### Selected Comparable Group

```text
Nissan Sunny
2014
Moderate mileage
```

### Result

| Feature | Listings with Feature | Feature Share | Median Listed Price |
|---|---:|---:|---:|
| Automatic | 10 | 71.43% | 490,000 EGP |
| Air Conditioner | 5 | 35.71% | 400,000 EGP |
| Remote Control | 5 | 35.71% | 400,000 EGP |
| Power Steering | 2 | 14.29% | 400,000 EGP |

### Interpretation

Automatic transmission is the most commonly listed feature within the selected comparable group, appearing in **71.43%** of comparable listings.

Feature share is calculated against the total number of comparable listings before expanding rows through the feature bridge table. This prevents feature assignments from being incorrectly counted as car listings.

Feature-level price differences should be interpreted as association, not causation. A higher price for listings with a feature does not prove that the feature alone caused the higher listed price.

---

## 5. Location Listing Counts and Listed-Price Benchmarks

### Question

How do listing counts and listed-price benchmarks differ by location?

### Method

Listings were grouped by location. Locations with fewer than 20 listings were excluded from the official benchmark output to avoid weak comparisons.

### Result Summary

The query returned **59 locations** with at least 20 listings.

Top locations by listing count included:

| Location | Listings | Median Listed Price | Median Mileage |
|---|---:|---:|---:|
| Cairo | 3,226 | 625,000 EGP | 140,000 km |
| Tagamo3 - New Cairo | 1,955 | 835,000 EGP | 120,000 km |
| 6 October | 1,606 | 650,000 EGP | 152,000 km |
| Alexandria | 1,536 | 550,000 EGP | 136,500 km |
| Nasr City | 1,132 | 692,500 EGP | 130,000 km |

### Interpretation

Listing availability is concentrated in major urban locations, especially Cairo and New Cairo.

Location-level price benchmarks differ partly because each location has a different mix of companies, models, mileage levels, and manufacturing years. Therefore, location should be interpreted as a market-availability and benchmark dimension, not as a direct cause of price differences.

---

## Limitations

- The project analyzes listed asking prices, not confirmed sold prices.
- Company and model values are based on source-listed text and may require deeper normalization in future versions.
- Feature values depend on source listing quality and may be incomplete or inconsistently provided.
- Location values come from source listings and may contain market-specific naming variation.
- Benchmark outputs are descriptive and should not be interpreted as guaranteed valuations.

## Final Summary

The final analysis model supports buyer and seller decision-making through validated star-schema queries.

The project provides:

- broad listed-price benchmarks by year and mileage,
- common vehicle options by budget segment,
- selected-car pricing benchmarks and pricing guidance,
- feature availability and feature-level price benchmarks,
- location-level listing availability and price benchmarks.

The strongest output of the project is a transparent decision-support workflow that connects data quality handling, dimensional modeling, SQL analysis, and business interpretation.
