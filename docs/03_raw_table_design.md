# Raw Table Design

## Purpose

The raw table is the safe landing layer for the original CSV data.

Its purpose is to preserve source values exactly as loaded while adding minimal metadata for traceability.

## Raw Table

```sql
raw.raw_used_car_listings_aug_2025
```

## Design Decisions

| Decision | Reason |
|---|---|
| Store source columns as `TEXT` | Prevent import failures and preserve messy source values |
| Generate `raw_listing_id` | Source data has no reliable primary key |
| Keep `detail_link` | Useful for traceability and duplicate checks |
| Add `source_file_name` | Supports audit and future reloads |
| Add `loaded_at` | Records load timestamp |

## Source Columns

All original CSV columns are stored as text in the raw table.

## Metadata Columns

| Column | Purpose |
|---|---|
| `raw_listing_id` | Internal generated primary key |
| `source_file_name` | Name of the loaded source file |
| `loaded_at` | Timestamp of database load |

## Why This Is Safe

This design separates source preservation from cleaning and analysis. The raw layer does not attempt to fix messy values. Cleaning happens later in documented SQL scripts.
