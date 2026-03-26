# Data structures for stochastic curtailment studies

struct Params
    sbase
    zbase
    voltage_high
    voltage_low
end

struct Prices
    energy
    raise_reg
    lower_reg
    raise_6_sec
    raise_60_sec
    raise_5_min
    lower_6_sec
    lower_60_sec
    lower_5_min
    probabilities
end

struct shaping_result
    trapeziums
    capacities
    OPF_data
end

struct OPF_data_new
    description
    objective_b
    objective_p
    optimality
    dispatch
    voltages
    nodal_max_transfer
    agg_max_transfers_active
    agg_max_transfers_reactive
    simulated_benefit
    currents
    simulated_dispatch
    tof_transfer
    time
end

struct naive_dispatch_data_new
    description
    dispatch
    objective
    nodal_extreme_bid_powers
end

struct naive_data
    NDD
    voltage
    current
    pg
end
