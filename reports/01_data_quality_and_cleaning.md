# 01 — Data quality & cleaning

Raw file: `data/raw/ercot_comprehensive_hourly_grid_dataset.xlsx`
Output:   `data/processed/ercot_hourly_clean.csv` (63,478 rows, one per UTC hour, no gaps)

## Summary

The workbook is well-organised (a `Hourly Data` sheet, a `Series Metadata` sheet, a `Read Me` sheet)
and the underlying numbers are sound — generation by fuel sums to net generation (mean abs error
**319 MW** on ~50,000 MW, i.e. ~0.6%), the eight weather-zone demands sum to system demand
(mean abs error **149 MW**), and `total_interchange = interchange_cen + interchange_swpp` holds.
But it is **not** ready to analyse as-is. Five issues, one of them structural.

### Issue 1 — Broken hourly timestamps (structural, ~4% of rows) — FIXED

Every value column is stored as **text** ("12805.0"), and the timestamp is an Excel date serial.
When decoded, the clock is wrong:

| symptom | count |
|---|---|
| rows in sheet | 63,478 |
| **distinct** hourly timestamps | 60,834 |
| timestamps that appear twice (always at **00:00 UTC**) | 2,644 |
| hourly slots with **no** row (always ~**05:00–06:00 UTC**) | 2,644 |

Walking the rows in sheet order shows the mechanism: roughly **one row per day** has the fractional
part of its serial dropped, so a timestamp that should read `…T05:00` is written as the bare date
integer `…T00:00`. That row then (a) collides with the real midnight row and (b) leaves the day's
05:00 slot empty. The two colliding rows carry **different** data (e.g. 2019-07-23 00:00: system
demand 63,617 vs 49,119 MWh), and the mis-stamped row's values interpolate smoothly with the
04:00 and 06:00 rows — i.e. the *data* is real, only the *timestamp* is corrupt.

Because UTC 05:00–06:00 maps to **local midnight**, a naïve analysis of the raw file shows DFW
demand at local hour 0 as essentially **zero** — a pure artifact.

**Fix (`scripts/01_build_clean_dataset.ps1`):** detect any row whose serial is `≤` the previous
row's serial *and* equals its own integer floor, and re-stamp it to `previous_hour + 1h` (the vacant
slot). 2,644 rows repaired; the result is a complete hourly clock with **0 gaps and 0 duplicates**.
Repaired rows are flagged in the column `timestamp_repaired` (1 = timestamp was reconstructed,
value untouched) so you can sensitivity-test any result against them.

### Issue 2 — Numbers stored as text — FIXED
All 21 measure columns were text. The cleaner parses them to real numbers; non-parseable / blank
cells become empty (true missing).

### Issue 3 — Coverage is narrower than the Read Me claims — DOCUMENTED
The `Read Me` sheet says "2019-01-01 through 2026-08-25, 67,038 rows". The actual `Hourly Data`
sheet starts **2019-05-27 06:00 UTC** (the first date the weather-zone demand series exist) and ends
**2026-08-23 03:00 UTC** — 63,478 hours. The `Series Metadata` sheet is internally consistent with
the shorter span. Treat 2019 as a **partial year** (5,256 h) in any annual comparison.

### Issue 4 — Small residual missingness — LEFT AS-IS (flagged, not imputed)
After the timestamp repair, missing *values* are 0.2% or less per column:

| column group | typical missing / 63,478 |
|---|---|
| generation (all fuels), net generation | 24–136 |
| weather-zone demand | 96–135 |
| interchange, total interchange | 106 |
| system demand | 1 |

Left as blanks so each modeller can choose (drop / forward-fill / interpolate). No single hour is
missing system demand *and* all zones.

### Issue 5 — Sign conventions / physical edge cases — DOCUMENTED, NOT ALTERED
- `interchange_*` and `total_interchange` are **signed** (≈ 40–60% negative). Positive = ERCOT
  exporting. Not errors.
- `generation_oth_mwh` has 2 slightly-negative values (min −8 MWh) and ~1,200 exact zeros —
  metering noise / no output. Kept.
- `generation_sun_mwh` is 0 for ~22,800 hours (night). Correct, not missing.
- DST: local time (`timestamp_local`) has one repeated wall-clock hour each November and one
  skipped hour each March. Expected; UTC is the clean join key.

## Columns added in the processed file

| column | meaning |
|---|---|
| `timestamp_utc` | clean hourly UTC (join key) |
| `timestamp_local` | America/Chicago wall clock |
| `date_local`, `year`, `month`, `day`, `doy`, `hour_utc`, `hour_local`, `dow_local`, `day_name`, `is_weekend`, `season`, `is_dst` | calendar features |
| `timestamp_repaired` | 1 if this hour's timestamp was reconstructed (Issue 1) |
| *(21 original measure columns, now numeric)* | unchanged values |
| `dfw_demand_mwh` | alias of `demand_ncen_mwh` (North Central = DFW) |
| `dfw_share_of_ercot` | `demand_ncen_mwh / demand_mwh` |
| `renewable_gen_mwh` | `wind + solar + hydro` (ERCOT-wide) |
| `renewable_share` | `renewable_gen_mwh / demand_mwh` |
| `net_load_mwh` | `demand_mwh − wind − solar` (ERCOT-wide) |
| `forecast_error_mwh` | `day_ahead_demand_forecast_mwh − demand_mwh` (system) |
| `abs_pct_error` | `|forecast_error_mwh| / demand_mwh × 100` |
