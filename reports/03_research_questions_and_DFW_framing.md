# 03 — DFW framing & research-question menu

## A. How to legitimately turn "N/S/E/W Texas" into "Dallas–Fort Worth"

The 8 zones in this dataset are **not** compass directions of the state — they are ERCOT's official
**weather zones** (load-forecasting regions). The mapping to real places:

| dataset column | ERCOT weather zone | metro / character |
|---|---|---|
| **`demand_ncen_mwh`** | **North Central** | **Dallas–Fort Worth metroplex** (Dallas, Tarrant, Collin, Denton, + ~15 surrounding counties) |
| `demand_coas_mwh` | Coast | Houston / Galveston |
| `demand_scen_mwh` | South Central | Austin / San Antonio |
| `demand_sout_mwh` | South | Corpus Christi / Rio Grande Valley |
| `demand_fwes_mwh` | Far West | Permian Basin (Midland–Odessa), oil & gas load |
| `demand_nrth_mwh` | North | Wichita Falls |
| `demand_east_mwh` | East | Tyler / Longview |
| `demand_west_mwh` | West | Abilene / San Angelo |

**So the reframe is one line:** *"study `demand_ncen_mwh` as DFW demand; use the other columns
(generation mix, forecast, interchange, other zones) as the Texas-grid context DFW sits inside."*
The eight zone demands sum to `demand_mwh` (verified, ~149 MW mean error), so `dfw_share_of_ercot`
is meaningful.

### What you *can* and *cannot* say at DFW resolution

| available at DFW (zone) level | only available ERCOT-wide |
|---|---|
| total hourly demand, its shape, growth, weather response, weekday/weekend, extremes | generation by fuel, renewable output, day-ahead demand forecast, imports/exports (interchange) |

Honest phrasings for DFW renewable/forecast questions:
- **DFW net load proxy** = `demand_ncen_mwh − dfw_share_of_ercot × (wind + solar)` — "if DFW drew its
  pro-rata slice of state renewables, what's left for gas to serve?"
- **Implied DFW forecast miss** = `forecast_error_mwh × dfw_share_of_ercot`.
Label these clearly as allocations, not measurements.

### Caveats to put in the methods section
- North Central ⊇ DFW: it includes exurban/rural counties, so it slightly over-states the metro.
- No prices (LMP), no weather, no wind/solar *by zone*, no transmission data in this file.
- 2019 starts 27 May (partial); ~0.2% values missing; DST gives one duplicate + one skipped local
  hour per year; the timestamp repair (see report 01) touched 2,644 rows' *timestamps*.

---

## B. Research questions (pick 1 primary + 2 supporting)

Each is answerable with the cleaned CSV alone, is DFW-specific, and is more pointed than
"analyse ERCOT demand". Ordered roughly by how distinctive they are.

### ★ Q1 — Why is DFW losing share of the Texas grid?
DFW demand rose 12% (2020→2025) while ERCOT rose 28%; DFW's share fell 31% → 28%.
- Decompose the share trend **by hour-of-day and by season** — is DFW losing share everywhere, or
  only overnight (where Permian/data-center load is growing), or only at peak?
- Compare DFW growth vs Far West and South Central growth rates.
- Deliverable: a stacked-area "who added the megawatts" chart, 2019→2026.
- *Why it's unique:* flips the usual "demand is growing" story into "growing **where**, and DFW is
  not the winner."

### ★ Q2 — Has the DFW peak hour drifted into the evening, and what does solar have to do with it?
Summer DFW peak now sits at 17:00–19:00 local and stays high to 19:00, on the solar down-ramp.
- For each summer 2019…2026, find the **hour of the DFW daily peak**; test for a trend (drift later).
- Build **DFW net load** (Section A proxy) and find *its* peak hour — show the gap between "demand
  peak" and "net-load peak" widening as solar scales.
- Relate to ERCOT solar capacity growth (0.5 → 9.8 GW avg).
- *Why it's unique:* the ERCOT "duck curve" localised to the single biggest load pocket.

### ★ Q3 — A DFW winter-reliability stress index
Uri (Feb 2021): DFW reached 25,766 MW — summer-class — then load was forcibly shed while wind fell
7.2→2.5 GW.
- Define a per-hour **stress score** for DFW winter: f(3-hour demand ramp, ERCOT wind share, ERCOT
  gas headroom = gas_max_seen − gas_now, temperature proxy via demand residual).
- Score every winter hour 2019–2026; rank the worst events (expect Feb 2021, Jan 2024 arctic blast,
  Jan 2025).
- Ask: how far below Uri were the *near-misses*, and is the ramp getting steeper each year?
- *Why it's unique:* most ERCOT reliability work is summer; DFW's real tail risk is a cold morning.

### ★ Q4 — Is DFW electrifying? Read it in the overnight floor.
The DFW overnight minimum grew +23% (7.4→9.1 GW) vs the peak's +9%.
- Fit annual trends of **nightly minimum** vs **daily maximum**; compute the DFW **load factor**
  (mean/peak) per year.
- Look for a rising 00:00–05:00 plateau (EV charging, data centers, heat pumps) and a weekly
  pattern change.
- Contrast with Far West (already flat/high load factor — industrial) as the "fully electrified"
  reference.
- *Why it's unique:* uses the boring hours nobody studies as the electrification signal.

### Q5 — Does the day-ahead forecast systematically under-serve the DFW afternoon?
System MAPE 2.44%, worst at hours 14–18, bias +259 MW overall but **+657 MW in 2025**.
- Construct implied DFW forecast error (Section A); regress its magnitude on DFW demand level and
  DFW 3-hour ramp.
- Is the growing 2025 bias concentrated in DFW summer afternoons? Would a DFW-share-weighted
  correction reduce system MAPE?

### Q6 — Load diversity: is Texas losing it as DFW peaks harder?
At the annual peak DFW is ~33% of ERCOT vs ~28% average; ncen–scen r = 0.93 but ncen–fwes r = 0.27.
- Compute Σ(zonal annual peaks) vs the coincident ERCOT peak → the **diversity benefit** in MW, per
  year. Is it shrinking (heat domes making all metros peak the same hour)?
- Rolling 30-day zone-to-zone correlation over 2019–2026.

### Q7 — The weekday premium as a work-from-home barometer
DFW weekday−weekend gap ≈ +566 (winter) to +750 MW (summer).
- Weekly-shape ratio (mean weekday / mean weekend) by month, 2019–2026: quantify the 2020 collapse
  and whether 2024–26 returned to the 2019 baseline.
- Compare DFW (office-heavy) vs South (residential/ag) vs Far West (24/7 industrial).

### Q8 — "The imported midnight": a data-engineering case study
Turn report 01's timestamp bug into a methods contribution.
- Show the naïve result (DFW demand at local hour 0 ≈ 0) vs repaired.
- Quantify the bias the artifact would inject into a diurnal regression / a peak-hour histogram.
- General lesson: always validate a datetime index (counts per hour-of-day, monotonicity) before
  trusting "clean" data.

### Q9 — When ERCOT runs >50% renewable, what is DFW doing?
- Classify every hour into DFW-demand tercile × ERCOT renewable-share tercile (3×3).
- Are the high-renewable hours the ones DFW needs power (summer afternoons, solar) or the ones it
  doesn't (mild spring nights, wind)? Quantify the "renewables arrive when DFW wants them" overlap
  and how it improved as solar grew.

---

## C. Suggested project shape

1. **Framing** (Section A) — DFW = North Central, with caveats. 1 page.
2. **Data & cleaning** — report 01, plus your own datetime-integrity checks (Q8 material). 2 pages.
3. **EDA** — report 02 figures, redrawn. 3–4 pages.
4. **Primary question** — one of Q1–Q4, with a model (trend / regression / index). 4–6 pages.
5. **Two supporting questions** — lighter treatment.
6. **Limitations & next data** — what LMP prices, zonal weather, or zonal generation would add.

## D. Extra data that would make it publishable (optional, external)
- NOAA/ASOS hourly temperature for DFW airport (KDFW) → real weather regressors instead of proxies.
- ERCOT settlement-point prices (LMP) for the North hub → add an economics dimension.
- ERCOT installed-capacity-by-fuel time series → convert "generation" into "capacity factor".
