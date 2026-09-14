# 02 — Exploratory findings

All figures from `data/processed/ercot_hourly_clean.csv` via `scripts/02_exploratory_analysis.ps1`.
"DFW" = ERCOT **North Central** weather zone (`demand_ncen_mwh`). MW = average MWh per hour.

---

## 1. DFW is the biggest load in Texas — but its *share* is shrinking

| year | hours | DFW avg (MW) | DFW min (MW) | DFW peak (MW) | ERCOT avg (MW) | DFW share |
|---|---:|---:|---:|---:|---:|---:|
| 2019* | 5,256 | 14,599 | 7,912 | 25,307 | 46,948 | 31.1% |
| 2020 | 8,784 | 13,156 | 7,439 | 25,548 | 43,376 | 30.3% |
| 2021 | 8,760 | 13,389 | 7,828 | 25,766 | 44,810 | 29.9% |
| 2022 | 8,760 | 14,683 | 8,068 | 27,569 | 49,156 | 29.9% |
| 2023 | 8,760 | 14,519 | 8,337 | 28,269 | 51,007 | 28.5% |
| 2024 | 8,784 | 14,786 | 8,797 | 27,959 | 52,798 | 28.0% |
| 2025 | 8,760 | 15,516 | 9,128 | 27,927 | 55,713 | 27.8% |
| 2026* | 5,614 | 16,358 | 9,472 | 29,839 | 58,386 | 28.0% |

\*partial year. **DFW absolute demand +12% (2020→2025); ERCOT +28%.** DFW's slice of the state
fell from ~31% to ~28%. Something else in Texas is growing much faster than DFW — a headline the
project can chase (Permian oil-field electrification, Austin/San-Antonio data centers, LNG on the
coast). The DFW *minimum* (overnight floor) rose faster (+23%, 7.4k→9.1k MW) than the DFW *peak*
(+9%) — consistent with always-on load (EV, data center, heat pump) filling in the nights.

## 2. DFW daily shape: a sharp summer evening peak, a broad winter double-hump

DFW average demand (MW) by local hour × season:

| local hr | Winter | Spring | Summer | Fall |
|---:|---:|---:|---:|---:|
| 04 | 12,211 | 9,934 | 13,717 | 10,625 |
| 08 | 14,925 | 11,599 | 14,215 | 12,236 |
| 12 | 14,131 | 13,067 | 18,890 | 14,203 |
| 15 | 13,235 | 13,926 | **21,988** | 15,657 |
| 17 | 13,232 | 14,417 | **22,838** | 16,208 |
| 18 | 13,719 | 14,557 | **22,874** | 16,277 |
| 20 | 14,375 | 14,182 | 21,626 | 15,564 |
| 23 | 13,429 | 12,812 | 18,544 | 13,500 |

- **Summer** is a single tall peak at **17:00–18:00 local**, ~23 GW, ~1.7× the pre-dawn trough.
- **Winter** is flatter with a **morning shoulder (08:00–10:00 ≈ 15 GW)** and a smaller evening bump —
  the classic heating/lighting profile, no single dominant hour.
- Spring/Fall are mild and low. The system is unambiguously **summer-cooling driven** in DFW.

## 3. The 15 highest DFW hours on record are **all in summer 2026**

| local time | DFW (MW) | ERCOT (MW) | wind (MW) | solar (MW) | DFW % of ERCOT |
|---|---:|---:|---:|---:|---:|
| 2026-07-22 17:00 | 29,839 | 90,966 | 3,370 | 30,545 | 32.8% |
| 2026-08-18 18:00 | 29,814 | 89,575 | 8,279 | 30,478 | 33.3% |
| 2026-08-18 17:00 | 29,705 | 89,456 | 7,682 | 32,141 | 33.2% |
| … (all 2026-07-22 and 2026-08-17..20, hours 16–19) | | | | | |

At the annual peak DFW is **~33%** of the whole grid (vs ~28% on average) — DFW peaks *harder* than
Texas as a whole. Note solar is running **30+ GW** during these peaks (it is what makes 90 GW
possible), but the peak has slid to **17:00–19:00**, i.e. into the solar down-ramp.

## 4. Weekday vs weekend (commercial load signature)

DFW average demand, weekday − weekend:

| season | weekday (MW) | weekend (MW) | weekday premium |
|---|---:|---:|---:|
| Winter | 13,749 | 13,183 | +566 |
| Spring | 12,687 | 12,011 | +677 |
| Summer | 18,282 | 17,532 | +750 |
| Fall | 13,744 | 13,056 | +688 |

A steady ~4–5% weekday premium — DFW carries real office/commercial load on top of residential.
Tracking this ratio year-by-year is a clean way to see the work-from-home dip and recovery.

## 5. Day-ahead demand forecast (ERCOT-wide) — good, but biased high in the afternoon

- Overall **MAPE 2.44%**, mean bias **+259 MW** (forecast slightly over actual).
- By year: best in 2026 (1.88%) and 2020 (2.21%); worst 2021 (2.88%, Uri). **2025 bias jumps to
  +657 MW** — worth investigating (load additions outrunning the forecast model?).
- Largest % error at **local hours 14–18** (2.7–2.8%) — exactly the DFW cooling ramp/peak. Since
  DFW is ~30% of load, most of that afternoon miss is a DFW-afternoon miss.

## 6. Statewide generation mix: wind flat-ish, **solar explosive**, gas the swing

ERCOT annual averages (MW):

| year | wind | solar | wind+solar | demand | renew. share* | net load | gas |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2019* | 8,538 | 506 | 9,045 | 46,948 | 19.3% | 37,903 | 23,496 |
| 2021 | 10,899 | 1,740 | 12,639 | 44,810 | 28.2% | 32,172 | 18,713 |
| 2023 | 12,328 | 3,638 | 15,966 | 51,007 | 31.3% | 35,041 | 22,997 |
| 2025 | 13,141 | 7,724 | 20,865 | 55,713 | 37.5% | 34,848 | 22,851 |
| 2026* | 14,594 | 9,795 | 24,390 | 58,386 | 41.8% | 33,996 | 22,418 |

\*renewable share here = (wind+solar+hydro)/demand, energy basis; instantaneous share goes far
higher. **Solar grew ~19× (0.5→9.8 GW avg).** Note **net load** (demand − wind − solar) has been
essentially **flat at ~33–35 GW since 2021** even as demand rose 30% — every added GW of demand has
been met by renewables, not thermal. That's the single most important grid-level story in the file.

## 7. How DFW moves with the rest of the grid (Pearson r vs DFW hourly demand)

| vs | r | reading |
|---|---:|---|
| ERCOT total demand | 0.949 | DFW basically *is* the shape of ERCOT demand |
| Day-ahead forecast (system) | 0.938 | |
| South Central demand (Austin/San Antonio) | 0.930 | same weather, same cooling cycle |
| Coast demand (Houston) | 0.853 | |
| North demand (Wichita Falls) | 0.711 | |
| **Far West demand (Permian)** | **0.267** | oil-field load — nearly weather-independent, own rhythm |
| Natural gas generation | 0.762 | gas follows DFW up |
| Coal generation | 0.572 | |
| Solar generation | 0.395 | positive: sunny = hot = DFW high (daytime) |
| Wind generation | −0.083 | wind ≈ uncorrelated with DFW need — the reliability problem |
| Total interchange | −0.175 | high DFW load → ERCOT imports (less export) |

The Far West contrast (r = 0.27) is a gift: it shows DFW and the Permian are **different kinds of
load**, which motivates treating "Texas" as at least two systems.

## 8. Spotlight — Winter Storm Uri (13–19 Feb 2021, local)

| date | DFW avg | DFW min | DFW max | ERCOT avg | wind avg | gas avg |
|---|---:|---:|---:|---:|---:|---:|
| 2021-02-13 | 20,339 | 18,418 | 22,941 | 58,720 | 4,034 | 37,191 |
| 2021-02-14 | 22,551 | 18,871 | **25,766** | 62,018 | 7,237 | 37,092 |
| 2021-02-15 | 18,815 | 16,724 | 24,086 | 50,152 | 3,223 | 32,202 |
| 2021-02-16 | 18,125 | **16,888** | 19,001 | 45,055 | 3,695 | 28,919 |
| 2021-02-17 | 18,791 | 17,792 | 20,050 | 45,160 | 2,546 | 29,810 |
| 2021-02-18 | 19,001 | 17,923 | 20,335 | 51,696 | 5,812 | 31,597 |
| 2021-02-19 | 18,100 | 14,553 | 21,697 | 49,153 | 6,007 | 27,003 |

Read it as: on **Feb 14** DFW hit **25,766 MW — a winter value on par with a summer peak** — then
demand *falls* on the 15th–16th. That fall is **load shed / rolling blackouts**, not people needing
less power: served load was forced down while wind collapsed (7.2 → 2.5 GW) and gas maxed out.
This one week is a ready-made case study for a "DFW winter reliability" question.
