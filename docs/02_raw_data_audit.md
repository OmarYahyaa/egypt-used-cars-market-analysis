# Raw Data Audit

## Purpose

This document summarizes the initial audit of the raw Egypt used-cars dataset before importing and cleaning.

The audit was performed to understand source structure, data risks, and the safest database import strategy.

## Dataset Overview

| Item | Value |
|---|---|
| File | `hatla2ee_cars_august_2025.csv` |
| Rows | 24,688 |
| Columns | 12 |
| Source | Kaggle / Hatla2ee used-car listings |

## Source Columns

```text
title
company
model
year
price
mileage
color
transmission
location
date_posted
features
detail_link
```

## Main Audit Findings

| Area | Finding | Design Decision |
|---|---|---|
| Price | Stored as text with commas and `EGP` | Store raw as text; clean later |
| Mileage | Stored as text with commas and `Km` | Store raw as text; clean later |
| Year | Contains unrealistic values such as `1100` and `5008` | Validate before converting |
| Date | Spreadsheet tools may display dates differently from raw CSV | Trust raw CSV source format |
| Features | Pipe-separated list | Model as features later if needed |
| Location | Some values may contain model/title information | Preserve raw value and flag suspicious values |
| Transmission | Mostly missing-like values | Keep for traceability, avoid main analysis |
| Detail link | Not fully unique | Use for duplicate checks, not as primary key |

## Primary Key Decision

The source data does not provide a reliable natural key.

Decision:

```text
Create a generated internal raw_listing_id in PostgreSQL.
Keep detail_link as a source reference and duplicate-detection field.
```

## Audit Conclusion

The dataset is usable for analysis, but it requires raw preservation, SQL-based cleaning, validation flags, careful duplicate handling, and documented limitations.
