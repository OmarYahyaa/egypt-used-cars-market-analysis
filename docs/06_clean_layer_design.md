# Clean Layer Design

## Purpose

The clean layer transforms raw source values into validated analytical fields while preserving traceability back to the raw layer.

The clean layer does not hide data quality problems. It stores source-preserved fields, cleaned analytical fields, and quality flags in the same table so analysis exclusions remain transparent.

## Clean Table

```sql
clean.clean_used_car_listings_aug_2025
```

Created by:

```text
sql/04_create_clean_table.sql
```

Populated by:

```text
sql/05_insert_clean_data.sql
```

## Design Principle

Each clean row should preserve the relationship between:

```text
source value
+ cleaned analytical value
+ quality flag
```

This design allows the analysis layer to filter reliable records while keeping the original source evidence available for review.

## Traceability Columns

| Column | Purpose |
|---|---|
| `raw_listing_id` | Links each clean row back to the raw table |
| `detail_link` | Source listing reference and duplicate-check field |
| `source_file_name` | Identifies the imported source file |
| `loaded_at` | Raw layer load timestamp |
| `cleaned_at` | Clean layer load timestamp |

## Source-Preserved Columns

| Column | Purpose |
|---|---|
| `source_title` | Original listing title |
| `source_company` | Original company value |
| `source_model` | Original model value |
| `source_color` | Original color value |
| `source_year` | Original manufacturing year value |
| `source_price` | Original listed price value |
| `source_mileage` | Original mileage value |
| `source_location` | Original location value |
| `source_features` | Original feature list |
| `source_transmission` | Original transmission value |
| `source_date_posted` | Original posting date value |

## Clean Analytical Columns

| Column | Purpose |
|---|---|
| `clean_manufacturing_year` | Valid numeric manufacturing year |
| `clean_price_egp` | Clean listed asking price in EGP |
| `clean_mileage_km` | Clean mileage in kilometers |
| `clean_location` | Validated location value |
| `clean_date_posted` | Valid posting date |

## Quality Flags

| Flag | Purpose |
|---|---|
| `year_quality_flag` | Classifies valid, missing, old, future, or invalid year values |
| `price_quality_flag` | Classifies valid, missing, suspicious, or invalid price values |
| `mileage_quality_flag` | Classifies valid, missing, zero, one-km, or suspicious mileage values |
| `location_quality_flag` | Classifies valid locations and likely model/title contamination |
| `date_quality_flag` | Classifies valid, missing, or invalid date values |
| `duplicate_quality_flag` | Classifies unique rows, first duplicate links, and duplicate extra rows |
| `is_analysis_ready` | Standard filter for official business analysis |

## Main Cleaning Decisions

| Area | Decision |
|---|---|
| Price | Convert valid prices to numeric EGP values; flag missing and suspicious prices |
| Mileage | Convert valid mileage values to numeric kilometers; flag missing and suspicious mileage |
| Year | Keep valid manufacturing years; set invalid analytical year values to `NULL` and flag them |
| Location | Set suspicious clean locations to `NULL` and flag likely model/title contamination |
| Duplicates | Preserve all rows; flag duplicate extra rows instead of deleting them silently |
| Transmission | Preserve source value for traceability; exclude from main analysis due to low coverage |

## Analysis-Ready Rule

A row is marked as analysis-ready when the core analytical fields are valid and the row is not a duplicate extra record.

```sql
WHERE is_analysis_ready = TRUE
```

This filter supports consistent business analysis while preserving non-ready records for auditability.
