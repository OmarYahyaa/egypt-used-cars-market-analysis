# Raw Data Quality Findings

## Purpose

This document summarizes the main quality findings from profiling the raw used-car listings.

Checks were performed on:

```sql
raw.raw_used_car_listings_aug_2025
```

## Row Count Validation

| Check | Row Count | Expected | Status |
|---|---:|---:|---|
| Staging table | 24,688 | 24,688 | PASS |
| Final raw table | 24,688 | 24,688 | PASS |

No rows were lost during import.

## Missing Values

| Column | Missing Count | Missing Percent |
|---|---:|---:|
| transmission | 24,381 | 98.76% |
| features | 7,818 | 31.67% |
| mileage | 1,410 | 5.71% |
| price | 109 | 0.44% |
| year | 6 | 0.02% |

Core descriptive fields were mostly complete, but several analysis fields required careful treatment.

## Duplicate Findings

| Duplicate Check | Duplicate Groups | Extra Rows |
|---|---:|---:|
| Repeated `detail_link` | 61 | 131 |
| Exact duplicate rows | 61 | 125 |

Repeated `detail_link` values are not all exact duplicates. Therefore, duplicates should be flagged carefully instead of deleted blindly.

## Year Quality

| Check | Result |
|---|---:|
| Missing years | 6 |
| Years before 1950 | 11 |
| Years after 2026 | 349 |
| Invalid year count | 360 |
| Minimum numeric year | 1100 |
| Maximum numeric year | 5008 |

## Price Quality

| Check | Result |
|---|---:|
| Missing-like prices | 109 |
| Non-numeric after cleaning | 0 |
| Minimum numeric price | 1,111 |
| Maximum numeric price | 1,000,000,000 |
| Suspicious low prices `< 50,000 EGP` | 108 |
| Suspicious high prices `> 20,000,000 EGP` | 9 |

## Mileage Quality

| Check | Result |
|---|---:|
| Missing-like mileage | 1,410 |
| Non-numeric after cleaning | 0 |
| Minimum numeric mileage | 0 |
| Maximum numeric mileage | 10,000,000 |
| Zero mileage count | 131 |
| One-km mileage count | 10 |
| Suspicious high mileage `> 500,000 km` | 127 |

## Transmission Coverage

| Value | Row Count | Percent |
|---|---:|---:|
| N/A | 24,381 | 98.76% |
| Automatic | 195 | 0.79% |
| Manual/manual | 112 | 0.45% |

Transmission coverage is too low for the main analysis.

## Location Quality

| Check | Result |
|---|---:|
| Missing-like locations | 0 |
| Distinct locations | 177 |
| Suspicious location rows | 106 |

## Feature Findings

| Check | Result |
|---|---:|
| Missing features | 7,818 |
| Non-missing features | 16,870 |
| Rows with `|` separator | 13,952 |
| Rows with only one feature | 2,918 |

The feature field is list-like and supports a future bridge-table design.

## Main Conclusion

The dataset is usable, but analysis requires a careful clean layer with numeric conversion, quality flags, duplicate handling, analysis-ready filtering, and documented exclusions.
