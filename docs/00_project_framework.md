# Project Framework

## Purpose

This document summarizes the analytical workflow used for the Egypt Used Cars Market Analysis project.

The project follows a SQL-first process inspired by CRISP-DM and layered data architecture. The workflow connects business understanding, raw data inspection, data quality profiling, clean transformation, business analysis, dimensional modeling, and final communication.

## Workflow Summary

```text
Business question
→ Raw data audit
→ Raw table design
→ Data quality profiling
→ Clean layer design
→ Clean data validation
→ SQL business analysis
→ Star schema design
→ Star schema validation
→ Portfolio communication
```

## Why This Framework Fits

The source data contains real-world marketplace issues, including messy text values, duplicated records, suspicious prices, invalid manufacturing years, and partially missing fields.

A structured workflow was required to:

- preserve raw evidence,
- avoid silent cleaning decisions,
- make data quality issues explicit,
- create analysis-ready fields,
- answer buyer and seller business questions,
- prepare a reporting model for future dashboarding.

## Layered Architecture

| Layer | Purpose | Main Output |
|---|---|---|
| Raw | Preserve source data as loaded | `raw.raw_used_car_listings_aug_2025` |
| Clean | Convert and validate analytical fields while preserving source values and quality flags | `clean.clean_used_car_listings_aug_2025` |
| Analysis | Provide a reporting-ready star schema for business questions and dashboarding | `analysis.fact_listed_car` and related dimensions |

## Key Principles

1. Define the business question before writing analysis queries.
2. Preserve the raw source before applying cleaning logic.
3. Profile data quality before defining cleaning rules.
4. Flag suspicious records instead of deleting them silently.
5. Validate row counts and quality flags after transformation.
6. Build the reporting model around the questions the dashboard must answer.
7. Document decisions, limitations, and scope clearly.

## Final Outcome

The project provides a complete analytics case study covering raw data ingestion, data quality profiling, clean layer design, business analysis, seller benchmark logic, dimensional modeling, and GitHub portfolio packaging.
