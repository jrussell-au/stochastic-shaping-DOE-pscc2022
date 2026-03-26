# Stochastic Shaping of Aggregator Energy and Reserve Bids to Ensure Network Security

Research code accompanying the paper:

> J.S. Russell, P. Scott, A. Attarha, "Stochastic shaping of aggregator energy and reserve bids to ensure network security," *Electric Power Systems Research*, vol. 212, 108418, 2022. doi: [10.1016/j.epsr.2022.108418](https://doi.org/10.1016/j.epsr.2022.108418)

## Abstract

Rising market participation of DER through aggregators increases the risk of network constraint violation at the distribution level. Existing approaches to network-secure DER coordination often require centralised resource management/oversight, or involve complex iterative negotiations between prosumers and the distribution service operator (DSO). In response to industry needs for readily-implementable solutions, we propose a straightforward network-secure bid curtailment approach performed by DSOs, allowing for separation of DSO and aggregator roles while factoring aggregator preferences communicated through bids. In extension to previous work, our approach directly maximises expected aggregator benefit in the market by factoring forecast market prices and bid prices into the objective. We mitigate risks of inaccurate market forecasts using a price-probabilistic stochastic program, bringing benefit to within 1% of the perfect information case in our simulations using real data. We demonstrate a 9% improvement in aggregator benefit compared to related approaches, with further gains available through real-reactive power co-optimisation.

## Overview

This code implements and compares **16 curtailment/bid-shaping methods** for battery aggregators operating on a 69-bus distribution network. The methods range from naive (unconstrained) dispatch to stochastic benefit-maximising optimisation with network power flow constraints.

### Key Contributions

- A variation of nodal operating envelopes that allocates capacity to aggregators based on the market value and bid value of services offered, achieving an **8% improvement** over alternative operating envelope approaches.
- A **stochastic programming extension** using price probability distributions that brings performance to within **less than 1%** of the perfect information case.
- Demonstration that **real-reactive power co-optimisation** can bring benefit to near 100% of the ideal unconstrained case.

### Curtailment Methods Compared

| Method | Description |
|--------|-------------|
| `naive` | Unconstrained dispatch (no network constraints) |
| `ideal_no_reactive` / `ideal_reactive` | Ideal dispatch with perfect information and full control |
| `benefit_pi` / `benefit_r_pi` | Benefit-maximising bid shaping with perfect price information |
| `benefit_p5` / `benefit_r_p5` | Benefit-maximising with 5-minute predispatch price forecasts |
| `benefit_p30` / `benefit_r_p30` | Benefit-maximising with 30-minute predispatch price forecasts |
| `benefit_stoch` / `benefit_r_stoch` | Stochastic benefit-maximising with price scenario PDFs |
| `l1_norm` / `l1_norm_r` | Power flow maximisation (L1 norm) |
| `l2_norm` / `l2_norm_r` | Power flow maximisation (L2 norm) |
| `equal_envelopes` | Equal envelope-based curtailment |

Methods suffixed with `_r` include reactive power optimisation.

### Network Model

- **69-bus radial distribution network** (IEEE 69-bus test feeder, 12.66 kV)
- DistFlow branch flow model with voltage (±5%) and current constraints
- 3 aggregators, each with 10 bid price bands across 12 NEM markets
- Markets: Energy (raise/lower), Regulation (raise/lower), Contingency FCAS (6-sec, 60-sec, 5-min raise/lower)
- 1910 customers with 50% prosumer penetration (5 kW / 10 kW inverters)

## Requirements

- **Julia 1.9+**
- **Ipopt** solver (open-source, installed automatically)
- No commercial solver licenses required

## Installation

```bash
cd "Stochastic Bid Shaping for ALlocative Efficiency"
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

## Usage

### Configuration

Edit [`config.jl`](config.jl) to set simulation parameters:

- **Time range**: `t_start` and `T` (default: single 5-min interval; set `T` to `DateTime(2021, 3, 12, 23, 55, 0)` for full day)
- **Region**: `state` — NEM region for price data (SA1, NSW1, QLD1, VIC1, TAS1)
- **Flags**: Enable/disable PV, loads, current limits, worst-case scenarios
- **Methods**: Comment out entries in `curtailment_types` to skip specific methods

### Running

```bash
julia --project=. stochastic_curtailment_studies.jl
```

A full-day simulation (288 time steps × 16 methods) runs for approximately 5–6 minutes per time step. Simulations use the Ipopt solver; reported results in the paper used an Intel Core i7-9700 3.00 GHz processor with 16 GB RAM.

## Project Structure

```
stochastic_curtailment_studies.jl   # Main entry point (imports, config, simulation loop)
config.jl                          # Simulation configuration (edit this)
src/
  types.jl                         # Data structures (Params, Prices, shaping_result, etc.)
  optimise.jl                      # Core optimisation algorithms (5 functions)
  network.jl                       # Network evaluation & power flow (3 functions)
  data_setup.jl                    # Data loading & preprocessing (6 functions)
  analysis.jl                      # Post-simulation analysis & plotting (22 functions)
  parse_batt_bids_data.jl          # Battery bid data parser (JSON → arrays)
data/
  allocations.csv                  # Customer-to-node allocation matrix
  loads_per_node.csv               # Aggregated load profiles per node
  pv_per_node.csv                  # Aggregated PV profiles per node
  batt-bids-*.json                 # Battery bid data (per date)
  data69bus_network.jl             # 69-bus network definition
  network_composition_dictionaries/# Prosumer allocation configurations
  load/                            # Customer load profiles (anonymised)
  predispatch_data_csv/            # NEM predispatch price forecasts
  price_data_csv/                  # NEM actual prices
  pv_data_csv/                     # PV generation profiles
  sensitivity_data_csv/            # Price sensitivity data
archive/                           # Legacy/unused files
```

## Data Sources

- **Network**: IEEE 69-bus test feeder (12.66 kV base) — branch data from Savier & Das (2007)
- **Prices**: Publicly available NEM predispatch and dispatch data (AEMO), SA1 region, 12 March 2021
- **Battery bids**: Historical bid data from Hornsdale Power Reserve, Lake Bonney Battery, and Ballarat Battery (12 March 2021)
- **Load profiles**: Anonymised residential prosumer data from a 30-household Tasmanian trial (Scott et al., 2019)
- **PV data**: Aggregated rooftop solar generation profiles

## Output

Results are stored in the `cs` (curtailment results) and `ns` (naive results) arrays, indexed by time step. Each entry contains:
- Optimised dispatch decisions
- Voltage profiles
- Current flows
- Objective values (expected and realised benefit)
- FCAS trapezium parameters

Analysis and plotting functions are included in the main script for post-processing.

## Citation

If you use this code in your research, please cite:

```bibtex
@article{Russell2022,
  title     = {Stochastic shaping of aggregator energy and reserve bids to ensure network security},
  author    = {Russell, James Stanley and Scott, Paul and Attarha, Ahmad},
  journal   = {Electric Power Systems Research},
  volume    = {212},
  pages     = {108418},
  year      = {2022},
  publisher = {Elsevier},
  doi       = {10.1016/j.epsr.2022.108418}
}
```

## License

See [LICENSE](LICENSE) for details.
