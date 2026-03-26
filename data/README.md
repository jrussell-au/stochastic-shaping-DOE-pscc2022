# Data Directory

This directory contains all input data for the stochastic bid-shaping simulations.

## Network

- **`69-bus-network.csv`** — Branch parameters for the IEEE 69-bus test feeder
- **`data69bus_network.jl`** / **`data69bus.jl`** — Julia network definitions (buses, branches, generators, loads)
- **`current_limits.csv`** — Branch current limits (amps)
- **`three_prosumer_network.jl`** / **`three_prosumer.jl`** — Simplified 3-prosumer test case

## Load Profiles (`load/`)

Anonymised residential prosumer load time-series data at 5-minute resolution.

- **`Paul_csvs/`** — Individual customer load profiles (hashed IDs, e.g. `U3NXVDWX-out.csv`)
  - Columns: `time, p_cp, p_inv, p_ld, p_pv, soc`
  - Time range: 2018–2019
- **`real_load_data_loads.csv`** — Aggregated load data per customer
- **`max_loads.csv`** — Maximum load per node
- **`nominal_loads.csv`** / **`unitary_loads.csv`** — Standardised load profiles

## PV Data (`pv_data_csv/`)

Rooftop solar PV generation profiles.

- **`real_load_data_pv.csv`** — Real PV generation data
- **`nominal_pv.csv`** / **`unitary_pv.csv`** — Standardised PV profiles

## Price Data

### Actual Prices (`price_data_csv/`)

True dispatch prices from the Australian NEM (publicly available from AEMO).

- Files named `{region}_{date}_prices.csv`
- Regions: SA1, TAS1
- Dates: 2021-01-22, 2021-03-12, 2021-06-14

### Predispatch Forecasts (`predispatch_data_csv/`)

AEMO predispatch price forecasts at 5-minute (p5) and 30-minute (p30) resolution.

- **`{region}_{date}_p5.csv`** — 5-minute predispatch
- **`{region}_{date}_p30.csv`** — 30-minute predispatch
- Regions: NSW1, QLD1, SA1, TAS1, VIC1
- Python extraction scripts: `extract_p5_info_from_csv.py`, `extract_p30_info_from_csv.py`

### Sensitivity Data (`sensitivity_data_csv/`)

Demand and price sensitivity data for the NEM.

## Network Composition (`network_composition_dictionaries/`)

Prosumer-to-node allocation dictionaries defining how battery resources are distributed across the network.

- **`real_load_data_composition_dictionary.jl`** — Default composition (used in main simulation)
- **`nominal_composition_dictionary.jl`** — Standard test composition
- **`heavily_unbalanced_*_composition_dictionary.jl`** — Stress-test configurations
- **`nodal_breakdown.csv`** — Summary of per-node allocations

## Demand Dictionary Generators

Python scripts for generating different network composition configurations:

- **`create_demand_dictionary.py`** — Standard configurations
- **`create_demand_dictionary_arbitrary_capped.py`** — Large-scale capped configurations
- **`create_demand_dictionary_unitary.py`** — Unit-capacity configurations
