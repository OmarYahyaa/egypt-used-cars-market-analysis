# Clean Data Validation Findings

## Purpose

This document summarizes validation results after loading transformed records into the clean layer.

Validation was performed on:

```sql
clean.clean_used_car_listings_aug_2025
```

## Row Count Validation

| Table | Row Count |
|---|---:|
| `raw.raw_used_car_listings_aug_2025` | 24,688 |
| `clean.clean_used_car_listings_aug_2025` | 24,688 |

No rows were lost during the clean insert.

## Analysis Readiness

| Status | Row Count |
|---|---:|
| Analysis-ready | 22,423 |
| Not ready | 2,265 |

The official business analysis uses:

```sql
WHERE is_analysis_ready = TRUE
```

## Quality Flag Validation

| Area | Main Result |
|---|---|
| Duplicates | 131 duplicate extra rows flagged |
| Price | 24,462 valid prices; suspicious values preserved and flagged |
| Mileage | 23,010 valid mileage values; suspicious values preserved and flagged |
| Year | 24,322 valid years; invalid years set to `NULL` and flagged |
| Location | 106 likely model-in-location rows flagged |
| Date | All 24,688 rows had valid dates |

## Validation Conclusion

The clean table is ready for official analysis because it preserves all raw rows, creates typed analytical fields, explains quality issues through flags, supports a consistent analysis-ready filter, and keeps traceability back to the raw source.
