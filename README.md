# DFW Electricity Demand on the Texas Grid — Capstone Project

**Source data:** *ERCOT Comprehensive Hourly Grid Dataset* (built from EIA `EBA.zip` / hourly electric grid monitor).
**Coverage:** 2019-05-27 06:00 → 2026-08-23 03:00 UTC, hourly. All values in megawatthours (MWh).
**Angle:** Reframe the project away from "compass directions of Texas" toward the **Dallas–Fort Worth metroplex**, using ERCOT's **North Central weather zone** (`demand_ncen_mwh`) as the DFW load signal, with statewide generation mix / forecast / interchange as context.

## Folder layout

```
CAPSTONE PROJECT/
├── README.md                         ← this file
├── data/
│   ├── raw/
│   │   └── ercot_comprehensive_hourly_grid_dataset.xlsx   ← original, untouched
│   └── processed/
│       ├── ercot_hourly_clean.csv    ← analysis-ready, tidy, one row per UTC hour
│       └── series_metadata.csv       ← 21 source series: IDs, definitions, zone meanings
├── reports/
│   ├── 01_data_quality_and_cleaning.md
│   ├── 02_exploratory_findings.md
│   ├── 03_research_questions_and_DFW_framing.md
│   └── column_profile.txt            ← auto-generated min/max/mean/missing per column
└── scripts/
    ├── 01_build_clean_dataset.ps1    ← raw .xlsx  →  data/processed/ercot_hourly_clean.csv
    └── 02_exploratory_analysis.ps1   ← clean csv  →  reports/02 numbers
```

## Regenerating the clean dataset

The scripts are PowerShell (no Python/pandas was available on this machine). To rebuild:

```powershell
# from the CAPSTONE PROJECT folder
powershell -File scripts/01_build_clean_dataset.ps1     # ~90 s, writes data/processed/ercot_hourly_clean.csv
powershell -File scripts/02_exploratory_analysis.ps1    # ~20 s, prints the EDA tables
```

If you move to Python, `data/processed/ercot_hourly_clean.csv` loads directly with
`pandas.read_csv(..., parse_dates=["timestamp_utc","timestamp_local"])`.

## What "clean" means here

The raw workbook is *mostly* clean but has one structural defect and a few cosmetic ones
(all documented in `reports/01_data_quality_and_cleaning.md`). The processed CSV fixes them and adds
derived columns (local time, calendar features, DFW share, renewable share, net load, forecast error).
