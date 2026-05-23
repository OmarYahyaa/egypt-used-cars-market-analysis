# Raw Data Quality Checks Plan

## Purpose

This document defines the quality checks needed before cleaning the raw used-car listings.

The goal is to measure data quality problems before deciding cleaning rules.

## SQL File

```text
sql/03_raw_data_quality_checks.sql
```

## Planned Checks

| Check Area | Purpose |
|---|---|
| Row counts | Confirm import completeness |
| Missing values | Identify null, empty, and placeholder values |
| Duplicates | Detect repeated `detail_link` and exact duplicate rows |
| Year quality | Find invalid or unrealistic manufacturing years |
| Price quality | Check convertibility and suspicious values |
| Mileage quality | Check convertibility and suspicious values |
| Transmission coverage | Decide whether the field is usable |
| Location quality | Detect suspicious location values |
| Feature structure | Understand pipe-separated feature values |
| Metadata | Confirm source file and load traceability |

## Key Principle

Raw profiling identifies problems. It does not automatically decide deletion rules.

Cleaning decisions are made later in the clean layer after the problems are measured and understood.
