# Configuration for Stochastic Curtailment Studies
# Modify these parameters to control the simulation

# ──────────────── Region & Time Settings ────────────────
state           = "SA1"                             # NEM region (e.g. SA1, NSW1, QLD1, VIC1, TAS1)
t_start         = DateTime(2021, 3, 12, 00, 00, 0)  # Simulation start time
T               = DateTime(2021, 3, 12, 00, 5, 0)   # Simulation end time (set to 23:55 for full day)
increment       = Minute(5)                          # Time step resolution
t_spike         = DateTime(2021, 1, 12, 18, 20, 0)  # Artificial price spike time (if enabled)
t_plummet       = DateTime(2021, 1, 12, 18, 0, 0)   # Artificial price plummet time (if enabled)

# ──────────────── Simulation Flags ────────────────
current_limits_in_effect    = 1     # 1 = enforce current limits, 0 = relaxed
pv_data_flag                = 1     # 1 = include PV generation data
load_data_flag              = 1     # 1 = include load data
load_part_of_energy         = 0     # 0 = load treated separately to energy in trapezium
reactive_power_norm         = 1     # 1 = L1 norm, 2 = L2 norm for real-reactive power relationship
add_worst_case              = 1     # 1 = add extreme scenarios to price PDF

# ──────────────── Network Composition ────────────────
factor          = 0.6               # Fraction of prosumers with 5kW battery inverter
compo_label     = "real_load_data"  # Composition dictionary label

# ──────────────── Artificial Modification Flags ────────────────
# Set to 1 to override default behaviour with artificial values
even_capacity_redistribution    = 0
stoch_through_p5_plus_margin    = 0
artificial_scenarios            = 0
art_true_flag                   = 0
art_p5_flag                     = 0
art_p30_flag                    = 0

scenario_prices         = [200; 500; 1200; 1400; 1900; 3000]
scenario_probabilities  = [0.1; 0.1; 0.3; 0.3; 0.1; 0.1]

art_true_prices = Prices([6000000], [78],  [11], [20], [89], [0.88],   [0.03],  [0.44],  [0.15],  [1])
art_p5_prices   = Prices([-17000],  [-10], [-10],[-10],[-10],[-10.00], [-10.0], [-10.0], [-10.0], [1])
art_p30_prices  = Prices([600],     [78],  [11], [20], [89], [0.88],   [0.03],  [0.44],  [0.15],  [1])

# ──────────────── Curtailment Methods ────────────────
# Comment out methods you don't want to run
curtailment_types = [
    "naive",
    "ideal_no_reactive",
    "ideal_reactive",
    "benefit_pi",       "benefit_r_pi",
    "benefit_p5",       "benefit_r_p5",
    "benefit_p30",      "benefit_r_p30",
    "benefit_stoch",    "benefit_r_stoch",
    "l1_norm",          "l1_norm_r",
    "l2_norm",          "l2_norm_r",
    "equal_envelopes",
]

# ──────────────── Output Settings ────────────────
keep_all_sim_data       = 1     # 1 = store full simulation results per time step
keep_benefit_results    = 0     # 1 = store benefit summary arrays
