# Capstone 2 idea (parked for next semester)

**Not part of Capstone 1 — noted here so it isn't lost.**

Turn the Capstone 1 forecasting work into a **live website**: pull fresh ERCOT/EIA data on a
schedule, run the forecasting model automatically, and display actual-vs-predicted demand plus a
map of the 8 ERCOT weather zones shaded by current/predicted load.

Key points from planning discussion:
- Map is realistically **zone-level** (8 ERCOT weather zones) — no public feed exists below that
  resolution. A bonus layer: individual power plants (EIA has lat/long + capacity) as a richer
  generation-source map.
- Data source options: **EIA API** (easy, ~1-day lag) vs **ERCOT's own public data** (truly
  real-time, but no simple documented API — the biggest unknown, should be spiked/tested in the
  first week or two of Capstone 2 before committing).
- Suggested stack: a scheduled script (e.g., GitHub Actions, free) to pull data + run the model,
  a small database, and a **Streamlit** site (fastest path given the team's Python background) —
  or a FastAPI + JS/Leaflet frontend if the team wants a more full-stack build.
- Rough shape: weeks 1-2 prove live data ingestion works, 3-5 wire up scheduled predictions,
  6-9 build the site/map, 10-12 deploy + stabilize, 13-14 polish/present.

Revisit this once Capstone 1 (data cleaning, EDA, forecasting model, proposal) is done.
