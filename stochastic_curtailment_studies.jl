println("Run Script - Stochastic Bid Shaping for Aggregator Benefit")
println("Importing packages...")
using Ipopt, JuMP, Dates, Statistics, Plots, Random, Distributions, JSON, StatsBase, CSV, DataFrames
println("Packages imported")

# Import network data
println("Importing network data...")
include("data/data69bus_network.jl")
include("src/parse_batt_bids_data.jl")
println("Network data imported")

# Load modular source files
include("src/types.jl")
include("src/optimise.jl")
include("src/network.jl")
include("src/data_setup.jl")
include("src/analysis.jl")

###############      PREPARE CURTAILMENTS        ###############
println("\nPreparing simulations...")

# Load configuration
include("config.jl")

println("\n----------------------------------------------------\nPARAMETERS:")
if load_part_of_energy == 1
    println("Load considered in energy trapezium")
else
    println("Load treated separately to energy in trapezium")
end
load_data_flag == 1 ? println("Using load data") : println("No load")
pv_data_flag == 1 ? println("Using PV data") : println("No PV")
println("Using l", reactive_power_norm, " norm for real-reactive power relationship")

print("Composition label: ", compo_label)
include(string("data/network_composition_dictionaries/",compo_label,"_composition_dictionary.jl"))

curr_lims = CSV.read("data//current_limits.csv", DataFrame);
curr_lims = curr_lims.current_limit .+ ((current_limits_in_effect == 0) * 99999)

max_loads = Array(CSV.read("data//load//max_loads.csv", DataFrame, header=false))*0.6;

cs  = []
ns  = []
envs_upper = []
envs_lower = []

load_df = CSV.read(string("data/loads_per_node.csv"), DataFrame, header=false)
load_mat = Matrix(load_df);

pv_df = CSV.read(string("data/pv_per_node.csv"), DataFrame, header=false)
pv_mat = Matrix(pv_df);

allocations_df = CSV.read(string("data/allocations.csv"), DataFrame, header=false)
allocations_mat = Matrix(allocations_df);

n_custs_per_node = sum(allocations_mat, dims=1)


start_last_time_step            = [Dates.now()]
end_last_time_step              = [Dates.now()]
println("\n----------------------------------------------------")
println("\nSimulations start time: ", Dates.now())

t = t_start;
for t in t_start:increment:T # NOTE THIS STARTS AT 0005 AND ENDS AT 2355

    t_old_system = Int64((t - DateTime(Date(t))) / Millisecond(1000*60*5) + 1)

    load_slice = load_mat[:,t_old_system] .* load_data_flag;# .* factor;
    for i in 1:69
        if load_slice[i] > max_loads[i]
            load_slice[i] = max_loads[i]
        end
    end
    pv_slice = pv_mat[:,t_old_system] .* pv_data_flag .* 0.5;
    println("\nTime step ", t)
    time_taken_by_last_time_step = end_last_time_step - start_last_time_step

    if t > t_start
        println("\nEstimated finish time: ", Dates.now() + Int64((T-t) / Millisecond(1000*60*5) + 1) *time_taken_by_last_time_step)
    end

    pdf_array = generate_price_pdf(t,state)
    if artificial_scenarios == 1
        pdf_array = [scenario_prices scenario_probabilities]
    else
        pdf_array = generate_price_pdf(t,state)
    end
    if add_worst_case == 1
        pdf_array = [-1000  0.00001; pdf_array; 15000  0.00001]
        pdf_array[2:(end-1),2] = pdf_array[2:(end-1),2] * 0.99998
        # pdf_array = [pdf_array; 15000  0.00001]
        # pdf_array[1:(end-1),2] = pdf_array[1:(end-1),2] * 0.99999
    end


    display(transpose(pdf_array))
    n_scens = size(pdf_array, 1)

    start_last_time_step[1] = Dates.now()

    bids, capacities, trapeziums, predicted_prices, predicted_prices_30, 
    simparams, trapezium_data, true_prices   = variable_setup(factor, "true prices", "expend_reactive_emax_to_match_energy",compo_label, t, state); # "true", "high",      "reg trapeziums", "reg trapeziums"

    if art_true_flag == 1
        true_prices = art_true_prices
    end
    if art_p5_flag == 1
        predicted_prices = art_p5_prices
    end
    if art_p30_flag == 1
        predicted_prices_30 = art_p30_prices
    end

    ############ ARTIFICIAL MODIFICATIONS ############

    if even_capacity_redistribution == 1
        for a in 1:3, i in 1:69, m in 1:12
            capacities[a, :, i, m] = ones(1,10) .* sum(capacities[a, :, i, m]) ./ 10
        end
    end

    if t == t_spike
        true_prices = Prices([8000] + 0 .* true_prices.energy, true_prices.raise_reg, true_prices.lower_reg, 
                                    true_prices.raise_6_sec, true_prices.raise_60_sec, true_prices.raise_5_min, 
                                    true_prices.lower_6_sec, true_prices.lower_60_sec, true_prices.lower_5_min, [1])
    end
    if t == t_plummet
        true_prices = Prices([-1000], true_prices.raise_reg, true_prices.lower_reg, 
                                    true_prices.raise_6_sec, true_prices.raise_60_sec, true_prices.raise_5_min, 
                                    [15000], true_prices.lower_60_sec, true_prices.lower_5_min, [1])
    end

    ##################################################

    if stoch_through_p5_plus_margin == 1
        n_scens = 3
        predicted_prices_stoch = Prices( [-100, predicted_prices.energy[1], minimum([100*predicted_prices.energy[1], 15000])],#[ -100; predicted_prices.energy[1]; minimum(100*predicted_prices.energy[1], 15000)],
                                    repeat([predicted_prices.raise_reg[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_reg[1]], outer=[n_scens]),
                                    repeat([predicted_prices.raise_6_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.raise_60_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.raise_5_min[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_6_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_60_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_5_min[1]], outer=[n_scens]),
                                    [0.05, 0.9, 0.05]
        )
    else
        predicted_prices_stoch = Prices( pdf_array[:,1],
                                    repeat([predicted_prices.raise_reg[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_reg[1]], outer=[n_scens]),
                                    repeat([predicted_prices.raise_6_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.raise_60_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.raise_5_min[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_6_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_60_sec[1]], outer=[n_scens]),
                                    repeat([predicted_prices.lower_5_min[1]], outer=[n_scens]),
                                    pdf_array[:,2]
        )
    end

    println("p30, p5 and true prices are as follows: ", [predicted_prices_30.energy[1], predicted_prices.energy[1], true_prices.energy[1]])

    #capacities
    extreme_bid_powers,   nodal_extreme_bid_powers,   max_transfers   = determine_nodal_extreme_bid_powers(trapeziums, capacities)
    #extreme_bid_powers_p, nodal_extreme_bid_powers_p, max_transfers_p = determine_nodal_extreme_profitable_bid_powers(trapeziums, capacities, prices)

    c_all = [];

    println(string("Calculating..."))

    print(string("    - Determining loss factor using p5 price estimate: "))
    benefit_p5_for_loss =               curtail_bids_stochastic(simparams, network, predicted_prices, true_prices,
                                                                bids, capacities, trapeziums, trapezium_data, 0, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_p5", 1, curr_lims, load_slice, pv_slice);
    loss_factor = pf_for_loss_estimate(simparams, network, benefit_p5_for_loss.OPF_data.dispatch, curr_lims, load_slice, pv_slice, bids)
    #loss_factor = 0.99
    println(loss_factor)

    println("    - Determining unconstrained benefit")
    if "naive" in curtailment_types
        naive_nd =                  naive_dispatch("Naive", true_prices, bids, capacities, trapeziums, loss_factor, load_slice, pv_slice, nodal_extreme_bid_powers)
        naive_v, naive_i, naive_pg = naive_dispatch_with_network(simparams, network, nodal_extreme_bid_powers, load_slice, pv_slice)
        naive_res = naive_data(naive_nd, naive_v, naive_i, naive_pg)
    end

    println(string("    - Determining optimal benefit (total control, perfect information)"))
    if "ideal_no_reactive" in curtailment_types
        ideal_no_reactive =             ideal_dispatch(simparams, network, true_prices, 
                                                        bids, capacities, trapeziums, trapezium_data, 0, 
                                                        extreme_bid_powers, nodal_extreme_bid_powers, 
                                                        "ideal_no_reactive", loss_factor, curr_lims, load_slice, pv_slice)
        push!(c_all, ideal_no_reactive)
    end
    if "ideal_reactive" in curtailment_types
        ideal_reactive =                ideal_dispatch(simparams, network, true_prices, 
                                                        bids, capacities, trapeziums, trapezium_data, 1, 
                                                        extreme_bid_powers, nodal_extreme_bid_powers, 
                                                        "ideal_reactive", loss_factor, curr_lims, load_slice, pv_slice)
        push!(c_all, ideal_reactive)
    end

    println(string("    - Performing network-secure bid shaping for aggregator benefit - perfect price infortmation"))
    if "benefit_pi" in curtailment_types
        benefit_pi =                    curtail_bids_stochastic(simparams, network, true_prices, true_prices, 
                                                                bids, capacities, trapeziums, trapezium_data, 0, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_pi", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_pi)
    end
    if "benefit_r_pi" in curtailment_types
        benefit_r_pi =                  curtail_bids_stochastic(simparams, network, true_prices, true_prices,             
                                                                bids, capacities, trapeziums, trapezium_data, 1, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_r_pi", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_r_pi)
    end

    println(string("    - Performing network-secure bid shaping for aggregator benefit - p5 predispatch"))
    if "benefit_p5" in curtailment_types
        benefit_p5 =                    curtail_bids_stochastic(simparams, network, predicted_prices, true_prices,
                                                                bids, capacities, trapeziums, trapezium_data, 0, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_p5", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_p5)
    end

    if "benefit_r_p5" in curtailment_types
        benefit_r_p5 =                  curtail_bids_stochastic(simparams, network, predicted_prices, true_prices,
                                                                bids, capacities, trapeziums, trapezium_data, 1, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_r_p5", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_r_p5)
    end

    println(string("    - Performing network-secure bid shaping for aggregator benefit - p30 predispatch"))
    if "benefit_p30" in curtailment_types
        benefit_p30 =                    curtail_bids_stochastic(simparams, network, predicted_prices_30, true_prices,
                                                                bids, capacities, trapeziums, trapezium_data, 0, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_p30", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_p30)
    end
    if "benefit_r_p30" in curtailment_types
        benefit_r_p30 =                  curtail_bids_stochastic(simparams, network, predicted_prices_30, true_prices,
                                                                bids, capacities, trapeziums, trapezium_data, 1, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_r_p30", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_r_p30)
    end

    println(string("    - Performing network-secure bid shaping for aggregator benefit - stochastic approach"))
    if "benefit_stoch" in curtailment_types
        benefit_stoch =                 curtail_bids_stochastic(simparams, network, predicted_prices_stoch, true_prices,
                                                                bids, capacities, trapeziums, trapezium_data, 0, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_stoch", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_stoch)
    end
    if "benefit_r_stoch" in curtailment_types
        benefit_r_stoch =               curtail_bids_stochastic(simparams, network, predicted_prices_stoch, true_prices,         
                                                                bids, capacities, trapeziums, trapezium_data, 1, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "benefit_r_stoch", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, benefit_r_stoch)
    end

    println(string("    - Performing network-secure bid shaping for maximum power flow"))
    if "l1_norm" in curtailment_types
        l1_norm =                       curtail_bids_power_flow(simparams, network, predicted_prices, true_prices, 1,      
                                                                bids, capacities, trapeziums, trapezium_data, 0, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "l1_norm", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, l1_norm)
    end
    if "l1_norm_r" in curtailment_types
        l1_norm_r =                     curtail_bids_power_flow(simparams, network, predicted_prices, true_prices, 1,
                                                                bids, capacities, trapeziums, trapezium_data, 1, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "l1_norm_r", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, l1_norm_r)
    end
    if "l2_norm" in curtailment_types
        l2_norm =                       curtail_bids_power_flow(simparams, network, predicted_prices, true_prices, 2,
                                                                bids, capacities, trapeziums, trapezium_data, 0, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "l2_norm", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, l2_norm)
    end
    if "l2_norm_r" in curtailment_types
        l2_norm_r =                     curtail_bids_power_flow(simparams, network, predicted_prices, true_prices, 2,
                                                                bids, capacities, trapeziums, trapezium_data, 1, 
                                                                extreme_bid_powers, nodal_extreme_bid_powers, 
                                                                "l2_norm_r", loss_factor, curr_lims, load_slice, pv_slice);
        push!(c_all, l2_norm_r)
    end

    println(string("    - Evaluating benefit under equal envelopes"))
    if "equal_envelopes" in curtailment_types
        equal_env, upper, lower = equal_envelopes(simparams, network, true_prices, bids, capacities, trapeziums, "equal envs", curr_lims, prosumer_composition, factor, loss_factor, max_loads)
        push!(envs_upper, upper)
        push!(envs_lower, lower)
        push!(c_all, equal_env)
    end

    println("Storing result data...")
    if keep_all_sim_data == 1
        push!(cs, c_all)
        push!(ns, naive_res)
    end
    println("Result data stored")

    end_last_time_step[1] = Dates.now()
end


println("Curtailments complete")
println("\nScript complete at ", Dates.now())

