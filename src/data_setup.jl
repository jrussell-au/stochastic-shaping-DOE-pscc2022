# Data loading, setup, and preprocessing functions
###############     INTERMEDIATE FUNCTIONS     ###############
function generate_equiprobable_prices(mu, sigma, pr_res)
    dr = Normal(mu, sigma)
    prices = quantile(dr, ((1:pr_res).-0.5)/pr_res)
    #prices = (prices .> 0) .* prices
    return prices
end

function variable_setup(factor, p_scenario, regulation_approach, compo_label, sim_datetime, state)
    bids, capacities, trapeziums = get_data(compo_label, sim_datetime)
    capacities = capacities .* factor
    trapeziums = trapeziums .* factor

    datestring = Dates.format(sim_datetime, "yyyymmdd")

    n_aggs  = size(trapeziums,1)
    n_nodes = size(trapeziums,3)
    n_traps = size(trapeziums,4)

    trapezium_data = zeros(n_aggs, n_nodes, n_traps, 2, 2)
    for a in 1:n_aggs, i in 1:n_nodes, tr in 1:n_traps
        trapezium_data[a,i,tr,1,1] = trapeziums[a,1,i,tr] / (trapeziums[a,4,i,tr] - trapeziums[a,2,i,tr])
        trapezium_data[a,i,tr,1,2] = - trapeziums[a,2,i,tr] * trapezium_data[a,i,tr,1,1]
        trapezium_data[a,i,tr,2,1] = - trapeziums[a,1,i,tr] / (trapeziums[a,3,i,tr] - trapeziums[a,5,i,tr])
        trapezium_data[a,i,tr,2,2] = - trapeziums[a,3,i,tr] * trapezium_data[a,i,tr,2,1]
    end

    # Note s_base is in the unit of kVA, which is also the unit of imported bid capacity and trapezium data
    # z_base formula should be v_base^2 / s_base, but factor of 1000 off is due to the fact s_base variable is in unit of kVA instead of VA
    s_base = 100;
    v_base = (12.66)*1000;                      # in V
    z_base = (v_base^2 / 1000) / s_base;         # division through 1000 because units for kV values in equation is kV

    simparams = Params(s_base, z_base, 1.05^2, 0.95^2)
    
    true_price_df = CSV.read(string("data/price_data_csv/", state, "_", datestring,"_true_prices.csv"), DataFrame, dateformat="yyyy-mm-dd HH:MM:SS")
    true_price_t_df = true_price_df[true_price_df.SETTLEMENTDATE .== sim_datetime,:]
    true_prices = Prices(   [true_price_t_df.RRP[1]],
                            [true_price_t_df.RAISEREGRRP[1]],
                            [true_price_t_df.LOWERREGRRP[1]],
                            [true_price_t_df.RAISE6SECRRP[1]],
                            [true_price_t_df.RAISE60SECRRP[1]],
                            [true_price_t_df.RAISE5MINRRP[1]],
                            [true_price_t_df.LOWER6SECRRP[1]],
                            [true_price_t_df.LOWER60SECRRP[1]],
                            [true_price_t_df.LOWER5MINRRP[1]],
                            [1])
    @assert(sum(true_prices.probabilities) == 1)

    println("\n\ntrue_price_t_df")
    println(true_price_t_df)

    if p_scenario == "true prices"
        predicted_prices = true_prices
        predicted_price_t_df = true_price_t_df
    end
    if p_scenario == "high prices"
        predicted_prices = Prices([99999],
            [99999],
            [-10],
            [99999],
            [-10],
            [-10],
            [-10],
            [-10],
            [-10],
            [1])
    end
    if p_scenario == "predicted prices"
        predicted_price_df = CSV.read(string("data/predispatch_data_csv/", state, "_", datestring,"_p5.csv"), DataFrame, dateformat="yyyy-mm-dd HH:MM:SS")
        predicted_price_t_df = predicted_price_df[predicted_price_df.INTERVAL_DATETIME .== sim_datetime,:]
        predicted_prices = Prices(  [predicted_price_t_df.RRP[1]],
                                    [predicted_price_t_df.RAISEREGRRP[1]],
                                    [predicted_price_t_df.LOWERREGRRP[1]],
                                    [predicted_price_t_df.RAISE6SECRRP[1]],
                                    [predicted_price_t_df.RAISE60SECRRP[1]],
                                    [predicted_price_t_df.RAISE5MINRRP[1]],
                                    [predicted_price_t_df.LOWER6SECRRP[1]],
                                    [predicted_price_t_df.LOWER60SECRRP[1]],
                                    [predicted_price_t_df.LOWER5MINRRP[1]],
                                    [1])
    end
    println("\n\npredicted_price_t_df")
    println(predicted_price_t_df)


    if regulation_approach == "expend_reactive_emax_to_match_energy"
        for a in 1:n_aggs, i in 1:n_nodes
            trapeziums[a,3,i,1] = sum(capacities[a, :, i, 1])
            trapeziums[a,5,i,1] = sum(capacities[a, :, i, 1]) - trapeziums[a,1,i,1]
            trapeziums[a,3,i,4] = sum(capacities[a, :, i, 2])
            trapeziums[a,5,i,4] = sum(capacities[a, :, i, 2]) - trapeziums[a,1,i,4]
        end
    end

    sim_datetime_plus_14 = sim_datetime + Minute(14)
    predicted_price_30_df = CSV.read(string("data/predispatch_data_csv/", state, "_", datestring,"_p30.csv"), DataFrame, dateformat="yyyy-mm-dd HH:MM:SS")
    predicted_price_30_t_df = predicted_price_30_df[abs.(predicted_price_30_df.DATETIME .- sim_datetime_plus_14) .<= Minute(15),:]
    #println("Using 30min predictions for time ", predicted_price_30_t_df.INTERVAL_TIME[1])
    predicted_prices_30 = Prices(  [predicted_price_30_t_df.RRP[1]],
                                [predicted_price_30_t_df.RAISEREGRRP[1]],
                                [predicted_price_30_t_df.LOWERREGRRP[1]],
                                [predicted_price_30_t_df.RAISE6SECRRP[1]],
                                [predicted_price_30_t_df.RAISE60SECRRP[1]],
                                [predicted_price_30_t_df.RAISE5MINRRP[1]],
                                [predicted_price_30_t_df.LOWER6SECRRP[1]],
                                [predicted_price_30_t_df.LOWER60SECRRP[1]],
                                [predicted_price_30_t_df.LOWER5MINRRP[1]],
                                [1])

    println("\n\npredicted_price_30_t_df")
    println(predicted_price_30_t_df)        

    #cd("Results")
    #sim_results_folder_name = string(Dates.format(Dates.now(), "dduyy-HHMM-SS"))
    #println("Variables established and data imported")
    return bids, capacities, trapeziums, predicted_prices, predicted_prices_30, simparams, trapezium_data, true_prices
end

function adjustments_for_difficult_formats(bids, capacities, trapeziums, prices, simparams)

    n_aggs = size(capacities,1)
    n_nodes = size(capacities,3)

    trapeziums[3,:,:,[1,2]] = trapeziums[3,:,:,[1,2]] * 1.875
    trapeziums[3,:,:,[3,4]] = trapeziums[3,:,:,[3,4]] * 1.5

    for a in 1:n_aggs, i in 1:n_nodes, tr_m in 3:10
        trapeziums[a,1,i,tr_m] = sum(capacities[a,:,i,tr_m + 2])
    end

    return bids, capacities, trapeziums, prices, simparams
end

function determine_nodal_extreme_bid_powers(trapeziums, capacities)

    # This function assumes FCAS trapeziums and max regulation value, NOT JOINT CAPACITY CONSTRAINT.

    gen = 1
    load = 2

    n_aggs =  size(capacities,1)
    n_bands = size(capacities,2)
    n_nodes = size(capacities,3)

    a_max = 1;
    e_max = 3;
    b_l   = 4;
    b_h   = 5;

    nodal_extremes  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(nodal_extremes, "print_level", 0)

    @variable(nodal_extremes, max_dispatch[a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, m_pairs in 1:8, m_p in 1:2])

    @objective(nodal_extremes, Max, 
        sum(max_dispatch)   
    )

    trap = 1
    dis1 = 2
    dis2 = 3

    MM = zeros(3, 8)
    MM[1,:] = [1, 4, 5, 6, 7, 8, 9, 10]             # Trapezium number
    MM[2,:] = [1, 2, 1, 1, 1, 2, 2, 2]              # Which energy market
    MM[3,:] = [3, 6, 7, 8, 9, 10, 11, 12]           # Market (reserve)

    for a in 1:n_aggs, i in 1:n_nodes, mcombo in 1:8

        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,   Int(MM[trap,mcombo])   ] > 0             # enablement min off zero
            @constraint(nodal_extremes,              
                        sum(max_dispatch[a,c,i,mcombo,2] for c in 1:n_bands)
                        <= sum(max_dispatch[a,c,i,mcombo,1] for c in 1:n_bands)
                        * trapeziums[a,a_max,i,   Int(MM[trap,mcombo])   ] / trapeziums[a,b_l,i,   Int(MM[trap,mcombo] )  ]
            )
        end
        # Flat top 2
        @constraint(nodal_extremes,              
                    sum(max_dispatch[a,c,i,mcombo,2] for c in 1:n_bands)
                    <= trapeziums[a,a_max,i,   Int(MM[trap,mcombo] )  ]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] - trapeziums[a,b_h,i,   Int(MM[trap,mcombo])   ]) > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(nodal_extremes,
                        sum(max_dispatch[a,c,i,mcombo,2] for c in 1:n_bands)
                        <= -(trapeziums[a,a_max,i,   Int(MM[trap,mcombo])   ] / (trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] - trapeziums[a,b_h,i,  Int( MM[trap,mcombo])   ])) *  sum(max_dispatch[a,c,i,mcombo,1] for c in 1:n_bands) 
                        + (trapeziums[a,a_max,i,   Int(MM[trap,mcombo])   ] * trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] / (trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] - trapeziums[a,b_h,i,   Int(MM[trap,mcombo] )  ]))
            )
        end

        # Max energy
        @constraint(nodal_extremes, sum(max_dispatch[a, c, i,mcombo,1] for c in 1:n_bands) <= sum(capacities[a, c, i, Int(MM[dis1,mcombo])  ] for c in 1:n_bands)   )
        # Max reserve
        @constraint(nodal_extremes, sum(max_dispatch[a, c, i,mcombo,2] for c in 1:n_bands) <= sum(capacities[a, c, i, Int(MM[dis2,mcombo])  ] for c in 1:n_bands)   )

    end

    status = JuMP.optimize!(nodal_extremes);

    max_dispatch_results = value.(max_dispatch)
    max_dispatch_results_summed_over_bands = sum(max_dispatch_results, dims=2)
    max_dispatch_results_summed_over_bands_over_pair = sum(max_dispatch_results_summed_over_bands, dims=5)

    extreme_bid_powers = zeros(n_aggs, n_nodes, 2)
    nodal_extreme_bid_powers = zeros(n_nodes, 2)

    for a in 1:n_aggs, i in 1:n_nodes
        extreme_bid_powers[a, i, 1] =                       maximum(max_dispatch_results_summed_over_bands_over_pair[a, 1, i, [1, 3, 4, 5], 1])
        extreme_bid_powers[a, i, 2] =                    -  maximum(max_dispatch_results_summed_over_bands_over_pair[a, 1, i, [2, 6, 7, 8], 1])
    end

    for i in 1:n_nodes
        nodal_extreme_bid_powers[i, gen] =                  sum(extreme_bid_powers[a, i, 1] for a in 1:n_aggs)
        nodal_extreme_bid_powers[i, load] =                 sum(extreme_bid_powers[a, i, 2] for a in 1:n_aggs)        
    end

    return extreme_bid_powers, nodal_extreme_bid_powers, max_dispatch_results

end

function determine_nodal_extreme_profitable_bid_powers(trapeziums, all_capacities, prices)

    gen = 1
    load = 2

    n_aggs =  size(all_capacities,1)
    n_bands = size(all_capacities,2)
    n_nodes = size(all_capacities,3)

    a_max = 1;
    e_max = 3;
    b_l   = 4;
    b_h   = 5;

    capacities = deepcopy(all_capacities)
    ###### set unprofitable capacities to zero ######
    for a in n_aggs, i in 1:n_nodes, c in 1:n_bands
        capacities[a, c, i, 1] =  all_capacities[a, c, i, 1]  .* (bids[a, c, 1]  < prices.energy[1])
        capacities[a, c, i, 2] =  all_capacities[a, c, i, 2]  .* (bids[a, c, 2]  > prices.energy[1])
        capacities[a, c, i, 3] =  all_capacities[a, c, i, 3]  .* (bids[a, c, 3]  < prices.raise_reg[1])
        capacities[a, c, i, 4] =  all_capacities[a, c, i, 4]  .* (bids[a, c, 4]  < prices.lower_reg[1])
        capacities[a, c, i, 5] =  all_capacities[a, c, i, 5]  .* (bids[a, c, 5]  < prices.raise_reg[1])
        capacities[a, c, i, 6] =  all_capacities[a, c, i, 6]  .* (bids[a, c, 6]  < prices.lower_reg[1])
        capacities[a, c, i, 7] =  all_capacities[a, c, i, 7]  .* (bids[a, c, 7]  < prices.raise_6_sec[1])
        capacities[a, c, i, 8] =  all_capacities[a, c, i, 8]  .* (bids[a, c, 8]  < prices.raise_60_sec[1])
        capacities[a, c, i, 9] =  all_capacities[a, c, i, 9]  .* (bids[a, c, 9]  < prices.raise_5_min[1])
        capacities[a, c, i, 10] = all_capacities[a, c, i, 10] .* (bids[a, c, 10] < prices.lower_6_sec[1])
        capacities[a, c, i, 11] = all_capacities[a, c, i, 11] .* (bids[a, c, 11] < prices.lower_60_sec[1])
        capacities[a, c, i, 12] = all_capacities[a, c, i, 12] .* (bids[a, c, 12] < prices.lower_5_min[1])
    end


    nodal_extremes  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(nodal_extremes, "print_level", 0)

    @variable(nodal_extremes, max_dispatch[a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, m_pairs in 1:8, m_p in 1:2])

    @objective(nodal_extremes, Max, 
        sum(max_dispatch)   
    )

    trap = 1
    dis1 = 2
    dis2 = 3

    MM = zeros(3, 8)
    MM[1,:] = [1, 4, 5, 6, 7, 8, 9, 10]
    MM[2,:] = [1, 2, 1, 1, 1, 2, 2, 2]
    MM[3,:] = [3, 6, 7, 8, 9, 10, 11, 12]

    for a in 1:n_aggs, i in 1:n_nodes, mcombo in 1:8

        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,   Int(MM[trap,mcombo])   ] > 0             # enablement min off zero
            @constraint(nodal_extremes,              
                        sum(max_dispatch[a,c,i,mcombo,2] for c in 1:n_bands)
                        <= sum(max_dispatch[a,c,i,mcombo,1] for c in 1:n_bands)
                        * trapeziums[a,a_max,i,   Int(MM[trap,mcombo])   ] / trapeziums[a,b_l,i,   Int(MM[trap,mcombo] )  ]
            )
        end
        # Flat top 2
        @constraint(nodal_extremes,              
                    sum(max_dispatch[a,c,i,mcombo,2] for c in 1:n_bands)
                    <= trapeziums[a,a_max,i,   Int(MM[trap,mcombo] )  ]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] - trapeziums[a,b_h,i,   Int(MM[trap,mcombo])   ]) > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(nodal_extremes,
                        sum(max_dispatch[a,c,i,mcombo,2] for c in 1:n_bands)
                        <= -(trapeziums[a,a_max,i,   Int(MM[trap,mcombo])   ] / (trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] - trapeziums[a,b_h,i,  Int( MM[trap,mcombo])   ])) *  sum(max_dispatch[a,c,i,mcombo,1] for c in 1:n_bands) 
                        + (trapeziums[a,a_max,i,   Int(MM[trap,mcombo])   ] * trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] / (trapeziums[a,e_max,i,   Int(MM[trap,mcombo])   ] - trapeziums[a,b_h,i,   Int(MM[trap,mcombo] )  ]))
            )
        end

        # Max energy
        @constraint(nodal_extremes, sum(max_dispatch[a, c, i,mcombo,1] for c in 1:n_bands) <= sum(capacities[a, c, i, Int(MM[dis1,mcombo])  ] for c in 1:n_bands)   )
        # Max reserve
        @constraint(nodal_extremes, sum(max_dispatch[a, c, i,mcombo,2] for c in 1:n_bands) <= sum(capacities[a, c, i, Int(MM[dis2,mcombo])  ] for c in 1:n_bands)   )

    end

    status = JuMP.optimize!(nodal_extremes);

    max_dispatch_results = value.(max_dispatch)
    max_dispatch_results_summed_over_bands = sum(max_dispatch_results, dims=2)
    max_dispatch_results_summed_over_bands_over_pair = sum(max_dispatch_results_summed_over_bands, dims=5)

    extreme_bid_powers = zeros(n_aggs, n_nodes, 2)
    nodal_extreme_bid_powers = zeros(n_nodes, 2)

    for a in 1:n_aggs, i in 1:n_nodes
        extreme_bid_powers[a, i, 1] =                       maximum(max_dispatch_results_summed_over_bands_over_pair[a, 1, i, [1, 3, 4, 5], 1])
        extreme_bid_powers[a, i, 2] =                    -  maximum(max_dispatch_results_summed_over_bands_over_pair[a, 1, i, [2, 6, 7, 8], 1])
    end

    for i in 1:n_nodes
        nodal_extreme_bid_powers[i, gen] =                  sum(extreme_bid_powers[a, i, 1] for a in 1:n_aggs)
        nodal_extreme_bid_powers[i, load] =                 sum(extreme_bid_powers[a, i, 2] for a in 1:n_aggs)        
    end

    return extreme_bid_powers, nodal_extreme_bid_powers, max_dispatch_results

end

function generate_price_pdf(sim_time, state)

    sim_time_plus_14 = sim_time + Minute(14)

    if Time(sim_time) < Time(0, 30)
        sim_time = DateTime(Date(sim_time) + Time(0, 30))
    end

    #print("Actual t: ", t)

    load = 1
    #   

    datestring = Dates.format(sim_time, "yyyymmdd")

    # state being turned into a string
    t = 26
    #print(t)

    psens_df    = CSV.read(string("data/sensitivity_data_csv/AUS_", datestring, "_psens.csv"), DataFrame, dateformat="yyyy/mm/dd HH:MM:SS")
    fod_df      = CSV.read(string("data/sensitivity_data_csv/AUS_", datestring, "_demand.csv"), DataFrame, dateformat="yyyy-mm-dd HH:MM:SS")

    psens_t_df  = psens_df[abs.(psens_df.DATETIME .- sim_time_plus_14) .<= Minute(15),:]
    p_sensitivity_values_df = psens_t_df[psens_t_df.REGIONID .== state,:]
    demand_forecasts_df    = fod_df[abs.(fod_df.INTERVAL_DATETIME .- sim_time_plus_14) .<= Minute(15),:]

    p_sensitivity_values = Array(psens_t_df[psens_t_df.REGIONID .== state,4:end])
    demand_forecasts    = Array(fod_df[abs.(fod_df.INTERVAL_DATETIME .- sim_time_plus_14) .<= Minute(15),4:6])

    #print(p_sensitivity_values_df)
    #print(demand_forecasts_df)

    # # REGIONID,INTERVAL_DATETIME,OPERATIONAL_DEMAND_POE10,OPERATIONAL_DEMAND_POE50,OPERATIONAL_DEMAND_POE90

    # psens_array = Array(psens_df)
    # fod_array   = Array(fod_df)

    # #print(size(psens_array))
    # #print(size(fod_array))

    # psens_array_sliced = psens_array[:,:]
    # fod_array_sliced   = fod_array[:,:]

    # #print(psens_array)
    # #print(fod_array)

    # p_sensitivity_values = psens_array_sliced[5*(t-1) + state,4:end]
    # #println("sensitivity values: ",p_sensitivity_values)
    # demand_forecasts = fod_array_sliced[ 5*(t-1) + 1: 5*(t-1) + 5, 4:6]
    # #println("demand forecasts: ",demand_forecasts)

    state_order = ["NSW1", "QLD1", "SA1", "TAS1", "VIC1"]

    pd_matrix = [
        [100,       0,      0,      0,      0],
        [-100,      0,      0,      0,      0],
        [200,       0,      0,      0,      0],
        [-200,      0,      0,      0,      0],
        [500,       0,      0,      0,      0],
        [-500,      0,      0,      0,      0],
        [1000,      0,      0,      0,      0],

        [0,         0,      0,      0,      100],
        [0,         0,      0,      0,      -100],
        [0,         0,      0,      0,      200],
        [0,         0,      0,      0,      -200],
        [0,         0,      0,      0,      500],
        [0,         0,      0,      0,      -500],
        [0,         0,      0,      0,      1000],

        [0,         0,      50,     0,      0],
        [0,         0,      -50,    0,      0],
        [0,         0,      100,    0,      0],
        [0,         0,      -100,   0,      0],
        [0,         0,      200,    0,      0],
        [0,         0,      -200,   0,      0],

        [200,       100,    50,     0,      100],
        [-200,      -100,   -50,    0,      -100],
        [400,       200,    100,    0,      200],
        [-400,      -200,   -100,   0,      -200],

        [0,         100,    0,      0,      0],
        [0,         -100,   0,      0,      0],
        [0,         200,    0,      0,      0],
        [0,         -200,   0,      0,      0],
        [0,         500,    0,      0,      0],
        [0,         -500,   0,      0,      0],
        [0,         1000,   0,      0,      0],

        [0,         0,      0,      50,     0],
        [0,         0,      0,      -50,    0],
        [0,         0,      0,      100,    0],
        [0,         0,      0,      -100,   0],
        [0,         0,      0,      150,    0],
        [0,         0,      0,      -150,   0],
        [0,         0,      0,      300,    0],

        [0,         0,      500,    0,      0]
    ];

    # determine probability of each scenario
    dists = []

    for state in 1:length(state_order)
        d = Normal(demand_forecasts[state,2], (demand_forecasts[state,2] - demand_forecasts[state,3])/1.28)
        push!(dists,d)
    end


    # generate gaussians for prices
    scenario_probability_and_price = zeros(39, 2)
    scenario_probability_statewise = zeros(39, 5)
    for sc in 1:39
        for state in 1:5
            scenario_probability_statewise[sc, state] = pdf(dists[state], demand_forecasts[state,2] + pd_matrix[sc][state])
        end
        scenario_probability_and_price[sc, 1] = prod(scenario_probability_statewise[sc, :])
        scenario_probability_and_price[sc, 2] = p_sensitivity_values[sc]
    end

    A = scenario_probability_and_price;
    A2 = A[sortperm(A[:,2]), :];
    A3 = [A2[:,2] cumsum(A2[:,1])];
    A4 = [A3[:,1] A3[:,2]./A3[end,2]];

    empirical_cdf = A4;

    #probabilities_of_interest = [0.01, 0.1, 0.3, 0.5, 0.7, 0.9, 0.99]
    probabilities_of_interest = [0, 0.01, 0.2, 0.4, 0.6, 0.8, 0.9, 0.99, 1]

    final_prob_information = zeros(length(probabilities_of_interest), 2)

    for prob_index in 1:length(probabilities_of_interest)
        if probabilities_of_interest[prob_index] <= 0.5
            final_prob_information[prob_index, 1] = empirical_cdf[minimum(findall(>(probabilities_of_interest[prob_index]),empirical_cdf[:,2])),2]
            final_prob_information[prob_index, 2] = empirical_cdf[minimum(findall(>(probabilities_of_interest[prob_index]),empirical_cdf[:,2])),1]
        else
            final_prob_information[prob_index, 1] = empirical_cdf[maximum(findall(<(probabilities_of_interest[prob_index]),empirical_cdf[:,2])),2]
            final_prob_information[prob_index, 2] = empirical_cdf[maximum(findall(<(probabilities_of_interest[prob_index]),empirical_cdf[:,2])),1]
        end
    end

    pdf_values = zeros(length(probabilities_of_interest)-1, 2)

    for pdf_row in 1:length(probabilities_of_interest)-1
        pdf_values[pdf_row, 1] = 1/2 * (final_prob_information[pdf_row, 2] + final_prob_information[pdf_row+1, 2])
        pdf_values[pdf_row, 2] = final_prob_information[pdf_row+1, 1] - final_prob_information[pdf_row, 1]
    end

    return pdf_values
end

