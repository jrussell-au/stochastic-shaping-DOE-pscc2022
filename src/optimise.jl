# Core optimization functions for stochastic curtailment studies
function curtail_bids_stochastic(simparams, network, prices, real_prices, bids, capacities, trapeziums, trapezium_data, reactive, extreme_bid_powers, nodal_extreme_bid_powers, description_input, loss_factor, curr_lims, load_slice, pv_slice)

    n_aggs =    size(bids, 1)
    n_bands =   size(bids, 2)
    n_nodes =   length(network.branch)+1;
    n_markets = size(bids, 3)

    gen = 1
    load = 2
    energy_raise    = 1
    energy_lower    = 2
    n_markets = 12

    n_scenarios   = length(prices.energy)
    probabilities = prices.probabilities
    #println("Number of scenarios: ",n_scenarios)

    prices_array = transpose([prices.energy prices.energy prices.raise_reg prices.lower_reg prices.raise_reg prices.lower_reg prices.raise_6_sec prices.raise_60_sec prices.raise_5_min prices.lower_6_sec prices.lower_60_sec prices.lower_5_min])
    agg_load_slice = load_slice; #sum(load_slice, dims=1)
    agg_pv_slice = pv_slice; #sum(pv_slice, dims=1)

    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)
    #set_optimizer_attribute(network_sim, "nlp_scaling_method", "none")

    # General variables
    @variable(network_sim, simparams.voltage_low <= vm[i in 1:n_nodes, d in [gen,load]] <= simparams.voltage_high)
    @variable(network_sim, -(curr_lims[l] / (100/12.66))^2 <= I[(l,i,j) in network.arcs, d in [gen,load]] <= (curr_lims[l] / (100/12.66))^2)
    @variable(network_sim, p[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, q[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, pg[i in keys(network.gen), d in [gen,load]]<=10000000*network.gen[i]["pmax"])
    @variable(network_sim, qg[i in keys(network.gen), d in [gen,load]])
    @variable(network_sim,   nodal_max_transfer[i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim,   aggre_max_transfer[a in 1:n_aggs,                 i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim, 0 <=        dispatch[a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= capacities[a,c,i,m])
    @variable(network_sim, 0 <=    dispatch_sum[a in 1:n_aggs,                 i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= sum(capacities[a,c,i,m] for c in 1:n_bands))
    @variable(network_sim, aggre_reactive_power[a in 1:n_aggs,                 i in 1:n_nodes, d in [gen,load]])

    # Objective: Maximise aggregator welfare (max revenue less costs)
    @objective(network_sim, Max,
        sum(
            probabilities[s] * (

                prices_array[energy_raise,s] * sum(dispatch[a,c,i,energy_raise,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) * loss_factor
                - sum(bids[a,c,energy_raise] * dispatch[a,c,i,energy_raise,s]  for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)

                - prices_array[energy_lower,s] * sum(dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) / loss_factor
                + sum(bids[a,c,energy_lower] * dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)

                + sum(prices_array[reserve_market,s] * loss_factor * dispatch[a,c,i,reserve_market,s] 
                for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)

                - sum(bids[a,c,reserve_market] * dispatch[a,c,i,reserve_market,s] 
                for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)

            ) for s in 1:n_scenarios
        ) / 12 / 1000
    );

    start_time_constraints = Dates.Time(Dates.now());

    @constraint(network_sim, d_sum[a in 1:n_aggs, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios],
                dispatch_sum[a, i, m, s] == sum(dispatch[a,c,i,m,s] for c in 1:n_bands))

    # Total transfer at a node is the sum of potential transfers at aggs
    @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in [gen, load]], 
        nodal_max_transfer[i, d] == sum(aggre_max_transfer[a,i,d] for a in 1:n_aggs)
    )

    @constraint(network_sim, cap_transfers_to_bids_gen[i in 1:n_nodes],                                 # Fine
        nodal_max_transfer[i, gen] <= nodal_extreme_bid_powers[i, gen]
    )
    
    @constraint(network_sim, cap_transfers_to_bids_load[i in 1:n_nodes],                                # Fine
        nodal_max_transfer[i, load] >= nodal_extreme_bid_powers[i, load]
    )   

    @constraint(network_sim, aggre_max_transfer_bounds_gen[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, gen]  >= 0)
    @constraint(network_sim, aggre_max_transfer_bounds_load[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, load] <= 0)

    @constraint(network_sim, aggre_max_transfer_bounds_gen_upper[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, gen]  <= extreme_bid_powers[a, i, gen])
    @constraint(network_sim, aggre_max_transfer_bounds_load_upper[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, load] >= extreme_bid_powers[a, i, load])

    # The following keys relate to trapezium vertices, not aggregagtors (a) or bands (b).
    a_max = 1;
    e_min = 2;
    e_max = 3;
    b_l   = 4;
    b_h   = 5;

    grad = 1
    offset = 2

    lower_slope = 1
    upper_slope = 2

    ############
        # Flags to determine whether regulation services available
        # Sum to 1
        # @constraint(network_sim, energy_flag_sums[a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]], 
        #               energy_below__reg_enablement[a, i, d]
        #             + energy_beyond_reg_enablement[a, i, d] 
        #             == 1
        #             )
        # # Encode flag meanings
        # @constraint(network_sim, energy_reg_flag_gen[a in 1:n_aggs, i in 1:n_nodes, s in 1:n_scenarios], 
        #             energy_beyond_reg_enablement[a, i, gen] => {dispatch_sum[a,i,gen,s] >= trapeziums[a, e_max, i, 1]}
        #             )
        # @constraint(network_sim, energy_reg_flag_load[a in 1:n_aggs, i in 1:n_nodes, s in 1:n_scenarios], 
        #             energy_beyond_reg_enablement[a, i, load] => {dispatch_sum[a,i,gen,s] >= trapeziums[a, e_max, i, 4]}
        #             )

    # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [3, 4],         s in 1:n_scenarios
        # Ramp 1 - (4, won't occur in market 3)     x=y markets
        if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0             # enablement min off zero
            @constraint(network_sim,              
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        <= 
                        (trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad] * dispatch_sum[a,i,gen,s] 
                        + trapezium_data[a,i,m_rel_to_gen-2,lower_slope,offset])
            )
            @constraint(network_sim,
                       dispatch_sum[a,i,gen,s] <= aggre_max_transfer[a, i, gen]
            ) 
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_gen,s] <= trapeziums[a,a_max,i,m_rel_to_gen-2]
        )
        # Ramp 3 - (3, won't occur in market 4)     x+y=k markets
        if trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(network_sim,
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        <= 
                            # energy_below__reg_enablement[a, i, gen]     # condition
                            (trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad] * dispatch_sum[a,i,gen,s] 
                                    + trapezium_data[a,i,m_rel_to_gen-2,upper_slope,offset]) # value
                            # +
                            # energy_beyond_reg_enablement[a, i, gen]      # condition
                            # * (0)        # value
            )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_gen,s] + dispatch_sum[a,i,gen,s] 
                        <= aggre_max_transfer[a, i, gen]
            )
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [7, 8, 9],      s in 1:n_scenarios
        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0
            @constraint(network_sim, 
                        dispatch_sum[a,i,gen,s]     # Energy
                        - dispatch_sum[a,i,4,s]     # Regulation lower
                        - (1 / trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen,s]
                        <= trapeziums[a,e_max,i,m_rel_to_gen-2]
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_gen,s]
                    <= trapeziums[a,a_max,i,m_rel_to_gen-2]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2]) > 0
            @constraint(network_sim,
                        dispatch_sum[a,i,gen,s]     # Energy
                        + dispatch_sum[a,i,3,s]     # Regulation raise
                        - (1 / trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen, s]
                        <= trapeziums[a,e_max,i,m_rel_to_gen-2]
            )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        + dispatch_sum[a,i,gen,s]
                        + dispatch_sum[a,i,3,s]
                        <= aggre_max_transfer[a, i, gen]
            )
        end
    end

    # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [5, 6],         s in 1:n_scenarios
        # Ramp 1 - (5, won't occur in market 6)     x=y markets
        if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0             # enablement min off zero
            @constraint(network_sim,              
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        <= 
                        trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad] * dispatch_sum[a,i,load,s] 
                        + trapezium_data[a,i,m_rel_to_lower-2,lower_slope,offset]
            )
            @constraint(network_sim,
                       dispatch_sum[a,i,load,s] <= -aggre_max_transfer[a, i, load]
            ) 
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_lower,s] <= trapeziums[a,a_max,i,m_rel_to_lower-2]
        )
        # Ramp 3 - (6, won't occur in market 5)     x+y=k markets
        if trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(network_sim,
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        <= 
            #                 energy_below__reg_enablement[a, i, load]
                            (trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad] * dispatch_sum[a,i,load,s] + trapezium_data[a,i,m_rel_to_lower-2,upper_slope,offset])
            #                 +
            #                 energy_beyond_reg_enablement[a, i, load]
            #                 * (0)
            )
            # @constraint(network_sim,
            #             dispatch_sum[a,i,m_rel_to_lower,s]
            #             <=  
            #                 1/30 *  log(
            #                     1 + exp(
            #                         (-dispatch_sum[a,i,load,s] + trapeziums[a, e_max, i, load])*30
            #                     )
            #                 )
            # )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_lower,s] + dispatch_sum[a,i,load,s] 
                        <= -aggre_max_transfer[a, i, load]
            )
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [10, 11, 12],      s in 1:n_scenarios
        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0
            @constraint(network_sim, 
                        dispatch_sum[a,i,load,s]     # Energy
                        - dispatch_sum[a,i,5,s]     # Regulation raise
                        - (1 / trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                        <= trapeziums[a,e_max,i,m_rel_to_lower-2]
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_lower,s]
                    <= trapeziums[a,a_max,i,m_rel_to_lower-2]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2]) > 0
            @constraint(network_sim,
                        dispatch_sum[a,i,load,s]     # Energy
                        + dispatch_sum[a,i,6,s]     # Regulation lower
                        - (1 / trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                        <= trapeziums[a,e_max,i,m_rel_to_lower-2]
            )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        + dispatch_sum[a,i,load,s]
                        + dispatch_sum[a,i,6,s]
                        <= -aggre_max_transfer[a, i, load]
            )
        end
    end

    # CHOOSE HOW TO DETERMINE MAX POWER
    # In reactive off case, this constraint seems to be binding
    if reactive == 1
        if reactive_power_norm == 1
            for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
        #     @NLconstraint(network_sim,  aggre_reactive_power[a, i, d]^2 + aggre_max_transfer[a, i, d]^2 <= extreme_bid_powers[a,i,d]^2)
                @constraint(network_sim,    aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] <= extreme_bid_powers[a,i,1])                       # on its own this stuffs everything up
                @constraint(network_sim,  - aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] <= - extreme_bid_powers[a,i,2])                   # somehow procludes zero reactive
                @constraint(network_sim,  - aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] >= - extreme_bid_powers[a,i,1])              
                @constraint(network_sim,    aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] >= extreme_bid_powers[a,i,2])

                # in our case, en_gen capacities are always greater than en_load, so:
                #@constraint(network_sim,    aggre_max_transfer[a,i,d] <= extreme_bid_powers[a,i,1])
                @constraint(network_sim,    aggre_reactive_power[a,i,d] >= extreme_bid_powers[a,i,2])                                                   # on their own, these 2 better than no reac
                @constraint(network_sim,    aggre_reactive_power[a,i,d] <= extreme_bid_powers[a,i,1])                                                   # makes sense, consistent with 0 in no reac

            end
        end
        if reactive_power_norm == 2
            for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
                @NLconstraint(network_sim,  aggre_reactive_power[a, i, d]^2 + aggre_max_transfer[a, i, d]^2 <= extreme_bid_powers[a,i,d]^2)                                              # makes sense, consistent with 0 in no reac
            end
        end
    end

    # SWITCH TO ACTIVE POWER ONLY
    if reactive == 0
        for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
            @constraint(network_sim, aggre_reactive_power[a, i, d] == 0)
        end
    end

    # Branch flow model
    bfm = 1
    if bfm == 1
        # BRANCH FLOW MODEL
        # Kirchoff constraints - real power
        @constraint(network_sim, high[i in 1:n_nodes, d in [gen,load]],
            sum(p[a,d] for a in network.bus_arcs[i]["to"])
            - sum((network.line_char[a]["br_r"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"]) 
            + sum(pg[g,d] for g in network.bus_gens[i])
            + (nodal_max_transfer[i,d] - agg_load_slice[i] - agg_pv_slice[i]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Kirchoff constraints - reactive power
        @constraint(network_sim, reac[i in 1:n_nodes, d in [gen,load]],
            sum(q[a,d] for a in network.bus_arcs[i]["to"] )
            - sum((network.line_char[a]["br_x"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"] ) 
            + sum(qg[g,d] for g in network.bus_gens[i])
            + sum(aggre_reactive_power[a,i,d] for a in 1:n_aggs) / simparams.sbase                  # + reactive power support here
            == sum(q[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Initial conditions
        @constraint(network_sim, top_voltage_high_gen,  vm[1,gen] ==1)
        @constraint(network_sim, top_voltage_high_load, vm[1,load]==1)
        # Voltage steps across branch as function of powers and current - gen scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,gen]
            q_fr = q[f_idx,gen]
            I_fr = I[f_idx,gen]
            vm_fr = vm[br["f_bus"],gen]
            vm_to = vm[br["t_bus"],gen]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
        # Voltage steps across branch as function of powers and current - load scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,load]
            q_fr = q[f_idx,load]
            I_fr = I[f_idx,load]
            vm_fr = vm[br["f_bus"],load]
            vm_to = vm[br["t_bus"],load]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
    end

    finish_time_constraints = Dates.Time(Dates.now());
    #print("Constraints time: ")
    #println(finish_time_constraints - start_time_constraints)

    # Run and report
    start_time_solve = Dates.Time(Dates.now());
    #println(start_time_solve)
    status = JuMP.optimize!(network_sim);
    opt = (termination_status(network_sim) == MOI.OPTIMAL);
    loc_sol = (termination_status(network_sim) == MOI.LOCALLY_SOLVED);
    #feasible = opt + loc_sol;
    finish_time_solve = Dates.Time(Dates.now());

    dp_vals = value.(dispatch);
    tight_aggre_max_transfer_scen = zeros(3, 69, 2, n_scenarios);
    for a in 1:n_aggs, i in 1:n_nodes, d in [1,2], s in 1:n_scenarios
        tight_aggre_max_transfer_scen[a, i, 1, s] = maximum(      sum(dp_vals[a,c,i,m,s] for c in 1:10, m in m_pair)     for m_pair in [[1,3,7],  [1,3,8],  [1,3,9]])
        tight_aggre_max_transfer_scen[a, i, 2, s] = maximum(      sum(dp_vals[a,c,i,m,s] for c in 1:10, m in m_pair)     for m_pair in [[2,6,10], [2,6,11], [2,6,12]])
    end

    tight_aggre_max_transfer = maximum(tight_aggre_max_transfer_scen, dims=4);
    tight_aggre_max_transfer[:,:,2] = -tight_aggre_max_transfer[:,:,2]
    # ready to sub in the below for new trapeium calculation
    
    # uncomment for tight aggregator transfer bounds
    aggre_max_transfer = tight_aggre_max_transfer;

    new_trapeziums = deepcopy(trapeziums)
    for a in 1:n_aggs, i in 1:n_nodes
        for m_pair in [1, 5, 6, 7]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer[a, i, gen])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer[a, i, gen])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([value.(aggre_max_transfer[a, i, gen]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        for m_pair in [4, 8, 9, 10]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer[a, i, load])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer[a, i, load])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([-value.(aggre_max_transfer[a, i, load]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        # Following can be commented out because trapezium shouldn't require changing if energy capacity is limited
            # for m_pair in [2]
            #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            # end
            # for m_pair in [3]
            #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            # end
    end

    ######
    # NEEDS SERIOUS RE-DOING
    new_capacities = zeros(size(capacities))
    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];

    for a in 1:n_aggs, i in 1:n_nodes, m_gen in [1]#, 3, 4, 7, 8, 9]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_gen]) < value.(aggre_max_transfer[a, i, gen])
                new_capacities[a,c,i,m_gen] = minimum([value.(aggre_max_transfer[a, i, gen]) - sum(new_capacities[a,1:(c-1),i,m_gen]), capacities[a,c,i,m_gen]])
            end
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_load in [2]#, 5, 6, 10, 11, 12]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_load]) < -value.(aggre_max_transfer[a, i, load])
                new_capacities[a,c,i,m_load] = minimum([-value.(aggre_max_transfer[a, i, load]) - sum(new_capacities[a,1:(c-1),i,m_load]), capacities[a,c,i,m_load]])
            end
        end
    end

    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];
    new_capacities[:,:,:,2] = new_capacities[:,end:-1:1,:,2];

    new_capacities[:,:,:,3:12] = capacities[:,:,:,3:12]

    if reactive == 1
        desc = "Stoch reactive      "
    else
        desc = "Stoch no reactive   "
    end

    # capped_capacities_1 = maximum(value.(dispatch), dims=5)
    # new_capacities = capped_capacities_1[:,:,:,:,1]

    #println(objective_value(network_sim))
    sb = naive_dispatch(description_input, real_prices, bids, new_capacities, new_trapeziums, loss_factor, load_slice, pv_slice, nodal_extreme_bid_powers)
    simulated_benefit = sb.objective
    #println(simulated_benefit)
    #println("Sim benefit: ", simulated_benefit)

    #println("Currents: ", value.(p))

    opf_data = OPF_data_new(description_input, objective_value(network_sim), 0, 
                [opt loc_sol], value.(dispatch), value.(vm), value.(nodal_max_transfer), 
                value.(aggre_max_transfer), value.(aggre_reactive_power), simulated_benefit, value.(I), sb.dispatch,
                [value.(pg[1,1]), value.(pg[1,2])], solve_time(network_sim))

    return shaping_result(new_trapeziums, new_capacities, opf_data)
end

function curtail_bids_power_flow(simparams, network, prices, real_prices, norm, bids, capacities, trapeziums, trapezium_data, reactive, extreme_bid_powers, nodal_extreme_bid_powers, description_input, loss_factor, curr_lims, load_slice, pv_slice)

    # Index variables for clarity
    n_aggs =    size(bids, 1)
    n_bands =   size(bids, 2)
    n_nodes =   length(network.branch)+1;
    n_markets = size(bids, 3)
    gen =       1
    load =      2
    n_markets = 12

    agg_load_slice = load_slice; #sum(load_slice, dims=1)
    agg_pv_slice = pv_slice; #sum(pv_slice, dims=1)

    # Declare model
    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)

    # General variables
    @variable(network_sim, simparams.voltage_low <= vm[i in 1:n_nodes, d in [gen,load]] <= simparams.voltage_high)
    @variable(network_sim, -(curr_lims[l] / (100/12.66))^2 <= I[(l,i,j) in network.arcs, d in [gen,load]] <= (curr_lims[l] / (100/12.66))^2)
    @variable(network_sim, p[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, q[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, pg[i in keys(network.gen), d in [gen,load]]<=10000000*network.gen[i]["pmax"])
    @variable(network_sim, qg[i in keys(network.gen), d in [gen,load]])
    @variable(network_sim,                  nodal_max_transfer[i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim,   aggre_max_transfer[a in 1:n_aggs, i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim, aggre_reactive_power[a in 1:n_aggs, i in 1:n_nodes, d in [gen,load]])

    if norm == 1
        @objective(network_sim, Min,
            # Sum of differences between 
                sum(nodal_extreme_bid_powers[i, gen] - nodal_max_transfer[i, gen]
                    for i in 1:n_nodes)
                + 
                sum(nodal_max_transfer[i, load] - nodal_extreme_bid_powers[i, load]
                    for i in 1:n_nodes)
        );
    end
    if norm == 2
        # Objective: Maximise aggregator welfare (max revenue less costs)
        @objective(network_sim, Min,
            # Sum of differences between 
                sum((nodal_extreme_bid_powers[i, gen] - nodal_max_transfer[i, gen])^2
                    for i in 1:n_nodes)
                + 
                sum((nodal_max_transfer[i, load] - nodal_extreme_bid_powers[i, load])^2
                    for i in 1:n_nodes)
        );
    end

    start_time_constraints = Dates.Time(Dates.now());

    @constraint(network_sim, aggre_max_transfer_bounds_gen[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i,  gen] >= 0)
    @constraint(network_sim, aggre_max_transfer_bounds_load[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, load] <= 0)

    @constraint(network_sim, aggre_max_transfer_bounds_gen_upper[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, gen]  <= extreme_bid_powers[a, i, gen])
    @constraint(network_sim, aggre_max_transfer_bounds_load_upper[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, load] >= extreme_bid_powers[a, i, load])

    # Total transfer at a node is the sum of potential transfers at aggs
    @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in [gen, load]], 
        nodal_max_transfer[i, d] == sum(aggre_max_transfer[a,i,d] for a in 1:n_aggs)
    )

    # CHOOSE HOW TO DETERMINE MAX POWER
    # In reactive off case, this constraint seems to be binding
    if reactive == 1
        if reactive_power_norm == 1
            for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
        #     @NLconstraint(network_sim,  aggre_reactive_power[a, i, d]^2 + aggre_max_transfer[a, i, d]^2 <= extreme_bid_powers[a,i,d]^2)
                @constraint(network_sim,    aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] <= extreme_bid_powers[a,i,1])                       # on its own this stuffs everything up
                @constraint(network_sim,  - aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] <= - extreme_bid_powers[a,i,2])                   # somehow procludes zero reactive
                @constraint(network_sim,  - aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] >= - extreme_bid_powers[a,i,1])              
                @constraint(network_sim,    aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] >= extreme_bid_powers[a,i,2])

                # in our case, en_gen capacities are always greater than en_load, so:
                #@constraint(network_sim,    aggre_max_transfer[a,i,d] <= extreme_bid_powers[a,i,1])
                @constraint(network_sim,    aggre_reactive_power[a,i,d] >= extreme_bid_powers[a,i,2])                                                   # on their own, these 2 better than no reac
                @constraint(network_sim,    aggre_reactive_power[a,i,d] <= extreme_bid_powers[a,i,1])                                                   # makes sense, consistent with 0 in no reac

            end
        end
        if reactive_power_norm == 2
            for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
                @NLconstraint(network_sim,  aggre_reactive_power[a, i, d]^2 + aggre_max_transfer[a, i, d]^2 <= extreme_bid_powers[a,i,d]^2)                                              # makes sense, consistent with 0 in no reac
            end
        end
    end

    # SWITCH TO ACTIVE POWER ONLY
    if reactive == 0
        for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
            @constraint(network_sim, aggre_reactive_power[a, i, d] == 0)
        end
    end

    @constraint(network_sim, cap_gen_curtailments[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, gen]  <= extreme_bid_powers[a, i, gen]
    )
    @constraint(network_sim, cap_load_curtailments[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, load] >= extreme_bid_powers[a, i, load]
    )

    # Branch flow model
    bfm = 1
    if bfm == 1
        # BRANCH FLOW MODEL
        # Kirchoff constraints - real power
        @constraint(network_sim, high[i in 1:n_nodes, d in [gen,load]],
            sum(p[a,d] for a in network.bus_arcs[i]["to"])
            - sum((network.line_char[a]["br_r"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"]) 
            + sum(pg[g,d] for g in network.bus_gens[i])
            + (nodal_max_transfer[i,d] - agg_load_slice[i] - agg_pv_slice[i]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Kirchoff constraints - reactive power
        @constraint(network_sim, reac[i in 1:n_nodes, d in [gen,load]],
            sum(q[a,d] for a in network.bus_arcs[i]["to"] )
            - sum((network.line_char[a]["br_x"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"] ) 
            + sum(qg[g,d] for g in network.bus_gens[i])
            + sum(aggre_reactive_power[a,i,d] for a in 1:n_aggs) / simparams.sbase                  # + reactive power support here
            == sum(q[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Initial conditions
        @constraint(network_sim, top_voltage_high_gen,  vm[1,gen] ==1)
        @constraint(network_sim, top_voltage_high_load, vm[1,load]==1)
        # Voltage steps across branch as function of powers and current - gen scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,gen]
            q_fr = q[f_idx,gen]
            I_fr = I[f_idx,gen]
            vm_fr = vm[br["f_bus"],gen]
            vm_to = vm[br["t_bus"],gen]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
        # Voltage steps across branch as function of powers and current - load scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,load]
            q_fr = q[f_idx,load]
            I_fr = I[f_idx,load]
            vm_fr = vm[br["f_bus"],load]
            vm_to = vm[br["t_bus"],load]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
    end

    finish_time_constraints = Dates.Time(Dates.now());
    #print("Constraints time: ")
    #println(finish_time_constraints - start_time_constraints)

    # Run and report
    start_time_solve = Dates.Time(Dates.now());
    #println(start_time_solve)
    status = JuMP.optimize!(network_sim);
    opt_1 = (termination_status(network_sim) == MOI.OPTIMAL);
    loc_sol_1 = (termination_status(network_sim) == MOI.LOCALLY_SOLVED);
    #feasible = opt + loc_sol;
    finish_time_solve = Dates.Time(Dates.now());
    #print("Solving time: ")
    #println(finish_time_solve - start_time_solve)

    # This determines nodal max power power_flows
    # Now create an optimisation problem which determines best aggre_max_transfers maximising aggregator benefit

    nodal_max_transfer_values = value.(nodal_max_transfer)

    if (reactive == 0) * (reactive_power_norm == 1)

        # Generate prices
        time_horizon = 1:1
        t = minimum(time_horizon)
    
        n_aggs =    size(bids, 1)
        n_bands =   size(bids, 2)
        n_nodes =   length(network.branch)+1;
        n_markets = size(bids, 3)
    
        gen = 1
        load = 2
        energy_raise    = 1
        energy_lower    = 2
        n_markets = 12
    
        n_scenarios   = length(prices.energy)
        probabilities = prices.probabilities
        #println("Number of scenarios: ",n_scenarios)
    
        prices_array = transpose([prices.energy prices.energy prices.raise_reg prices.lower_reg prices.raise_reg prices.lower_reg prices.raise_6_sec prices.raise_60_sec prices.raise_5_min prices.lower_6_sec prices.lower_60_sec prices.lower_5_min])        

        best_distribution  = Model(Ipopt.Optimizer)
        set_optimizer_attribute(best_distribution, "print_level", 0)
        @variable(best_distribution,   aggre_max_transfer_opt[a in 1:n_aggs, i in 1:n_nodes, d in [gen,load]])
        @variable(best_distribution, 0 <=     dispatch[a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= capacities[a,c,i,m])
        @variable(best_distribution, 0 <= dispatch_sum[a in 1:n_aggs,                 i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= sum(capacities[a,c,i,m] for c in 1:n_bands))
        # @variable(best_distribution, energy_beyond_reg_enablement[a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]], Bin)
        # @variable(best_distribution, energy_below__reg_enablement[a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]], Bin)

        @objective(best_distribution, Max,
            sum(
                probabilities[s] * (

                    prices_array[energy_raise,s] * sum(dispatch[a,c,i,energy_raise,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) * loss_factor
                    - sum(bids[a,c,energy_raise] * dispatch[a,c,i,energy_raise,s]  for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)
                    
                    - prices_array[energy_lower,s] * sum(dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) / loss_factor
                    + sum(bids[a,c,energy_lower] * dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)

                    + sum(prices_array[reserve_market,s] * loss_factor * dispatch[a,c,i,reserve_market,s] 
                    for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)

                    - sum(bids[a,c,reserve_market] * dispatch[a,c,i,reserve_market,s] 
                    for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)
                    
                ) for s in 1:n_scenarios
            ) / 12 / 1000
        );

        @constraint(best_distribution, d_sum[a in 1:n_aggs, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios],
                    dispatch_sum[a, i, m, s] == sum(dispatch[a,c,i,m,s] for c in 1:n_bands))

        # Total transfer at a node is the sum of potential transfers at aggs
        @constraint(best_distribution, agg_sum_max_transfers[i in 1:n_nodes, d in [gen, load]], 
            nodal_max_transfer_values[i, d] == sum(aggre_max_transfer_opt[a,i,d] for a in 1:n_aggs)
        )

        @constraint(best_distribution, aggre_max_transfer_bounds_gen[a in 1:n_aggs, i in 1:n_nodes],
            aggre_max_transfer_opt[a, i, gen] >= 0)
        @constraint(best_distribution, aggre_max_transfer_bounds_load[a in 1:n_aggs, i in 1:n_nodes],
            aggre_max_transfer_opt[a, i, load] <= 0)

        @constraint(best_distribution, aggre_max_transfer_bounds_gen_upper[a in 1:n_aggs, i in 1:n_nodes],
            aggre_max_transfer_opt[a, i, gen]  <= extreme_bid_powers[a, i, gen])
        @constraint(best_distribution, aggre_max_transfer_bounds_load_upper[a in 1:n_aggs, i in 1:n_nodes],
            aggre_max_transfer_opt[a, i, load] >= extreme_bid_powers[a, i, load])

        # The following keys relate to trapezium vertices, not aggregagtors (a) or bands (b).
        a_max = 1;
        e_min = 2;
        e_max = 3;
        b_l   = 4;
        b_h   = 5;

        grad = 1
        offset = 2

        lower_slope = 1
        upper_slope = 2


        # # Flags to determine whether regulation services available
        # # Sum to 1
        # @constraint(best_distribution, energy_flag_sums[a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]], 
        #             energy_below__reg_enablement[a, i, d]
        #             + energy_beyond_reg_enablement[a, i, d] 
        #             == 1
        #             )
        # # Encode flag meanings
        # @constraint(best_distribution, energy_reg_flag_gen[a in 1:n_aggs, i in 1:n_nodes, s in 1:n_scenarios], 
        #             energy_beyond_reg_enablement[a, i, gen] => {dispatch_sum[a,i,gen,s] >= trapeziums[a, e_max, i, 1]}
        #             )
        # @constraint(best_distribution, energy_reg_flag_load[a in 1:n_aggs, i in 1:n_nodes, s in 1:n_scenarios], 
        #             energy_beyond_reg_enablement[a, i, load] => {dispatch_sum[a,i,gen,s] >= trapeziums[a, e_max, i, 4]}
        #             )

        # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
        for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [3, 4],         s in 1:n_scenarios
            # Ramp 1 - (4, won't occur in market 3)     x=y markets
            if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0             # enablement min off zero
                @constraint(best_distribution,              
                            dispatch_sum[a,i,m_rel_to_gen,s]
                            <= 
                                # energy_below__reg_enablement[a, i, gen] *
                                (trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad] * dispatch_sum[a,i,gen,s] 
                                    + trapezium_data[a,i,m_rel_to_gen-2,lower_slope,offset])
                                # +
                                # energy_beyond_reg_enablement[a, i, gen]
                                # * (0)
                )
                @constraint(best_distribution,
                        dispatch_sum[a,i,gen,s] <= aggre_max_transfer_opt[a, i, gen]
                ) 
            end
            # Flat top 2
            @constraint(best_distribution,              
                        dispatch_sum[a,i,m_rel_to_gen,s] <= trapeziums[a,a_max,i,m_rel_to_gen-2]
            )
            # Ramp 3 - (3, won't occur in market 4)     x+y=k markets
            if trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
                @constraint(best_distribution,
                            dispatch_sum[a,i,m_rel_to_gen,s]
                            <= 
                                # energy_below__reg_enablement[a, i, gen] *     # condition
                                (trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad] * dispatch_sum[a,i,gen,s] 
                                        + trapezium_data[a,i,m_rel_to_gen-2,upper_slope,offset]) # value
                                # +
                                # energy_beyond_reg_enablement[a, i, gen]      # condition
                                # * (0)        # value
                )
                @constraint(best_distribution, 
                            dispatch_sum[a,i,m_rel_to_gen,s] + dispatch_sum[a,i,gen,s] 
                            <= aggre_max_transfer_opt[a, i, gen]
                )
            end
        end
        for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [7, 8, 9],      s in 1:n_scenarios
            # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
            if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0
                @constraint(best_distribution, 
                            dispatch_sum[a,i,gen,s]     # Energy
                            - dispatch_sum[a,i,4,s]     # Regulation lower
                            - (1 / trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen,s]
                            <= trapeziums[a,e_max,i,m_rel_to_gen-2]
                )
            end
            # Flat top 2
            @constraint(best_distribution,              
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        <= trapeziums[a,a_max,i,m_rel_to_gen-2]
            )
            # Ramp 3
            if (trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2]) > 0
                @constraint(best_distribution,
                            dispatch_sum[a,i,gen,s]     # Energy
                            + dispatch_sum[a,i,3,s]     # Regulation raise
                            - (1 / trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen, s]
                            <= trapeziums[a,e_max,i,m_rel_to_gen-2]
                )
                @constraint(best_distribution, 
                            dispatch_sum[a,i,m_rel_to_gen,s]
                            + dispatch_sum[a,i,gen,s]
                            + dispatch_sum[a,i,3,s]
                            <= aggre_max_transfer_opt[a, i, gen]
                )
            end
        end




        # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
        for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [5, 6],         s in 1:n_scenarios
            # Ramp 1 - (5, won't occur in market 6)     x=y markets
            if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0             # enablement min off zero
                @constraint(best_distribution,              
                            dispatch_sum[a,i,m_rel_to_lower,s]
                            <= 
                                # energy_below__reg_enablement[a, i, load] *
                                (trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad] * dispatch_sum[a,i,load,s] 
                                        + trapezium_data[a,i,m_rel_to_lower-2,lower_slope,offset])
                                # +
                                # energy_beyond_reg_enablement[a, i, load]
                                # * (0)
                )
                @constraint(best_distribution,
                        dispatch_sum[a,i,load,s] <= -aggre_max_transfer_opt[a, i, load]
                ) 
            end
            # Flat top 2
            @constraint(best_distribution,              
                        dispatch_sum[a,i,m_rel_to_lower,s] <= trapeziums[a,a_max,i,m_rel_to_lower-2]
            )
            # Ramp 3 - (6, won't occur in market 5)     x+y=k markets
            if trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
                @constraint(best_distribution,
                            dispatch_sum[a,i,m_rel_to_lower,s]
                            <= 
                                # energy_below__reg_enablement[a, i, load] *
                                (trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad] * dispatch_sum[a,i,load,s] + trapezium_data[a,i,m_rel_to_lower-2,upper_slope,offset])
                                # +
                                # energy_beyond_reg_enablement[a, i, load]
                                # * (0)
                )
                @constraint(best_distribution, 
                            dispatch_sum[a,i,m_rel_to_lower,s] + dispatch_sum[a,i,load,s] 
                            <= -aggre_max_transfer_opt[a, i, load]
                )
            end
        end
        for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [10, 11, 12],   s in 1:n_scenarios
            # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
            if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0
                @constraint(best_distribution, 
                            dispatch_sum[a,i,load,s]     # Energy
                            - dispatch_sum[a,i,5,s]     # Regulation lower
                            - (1 / trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                            <= trapeziums[a,e_max,i,m_rel_to_lower-2]
                )
            end
            # Flat top 2
            @constraint(best_distribution,              
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        <= trapeziums[a,a_max,i,m_rel_to_lower-2]
            )
            # Ramp 3
            if (trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2]) > 0
                @constraint(best_distribution,
                            dispatch_sum[a,i,load,s]     # Energy
                            + dispatch_sum[a,i,6,s]     # Regulation raise
                            - (1 / trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                            <= trapeziums[a,e_max,i,m_rel_to_lower-2]
                )
                @constraint(best_distribution, 
                            dispatch_sum[a,i,m_rel_to_lower,s]
                            + dispatch_sum[a,i,load,s]
                            + dispatch_sum[a,i,6,s]
                            <= -aggre_max_transfer_opt[a, i, load]
                )
            end
        end

        # Run and report
        start_time_solve = Dates.Time(Dates.now());
        #println(start_time_solve)
        status = JuMP.optimize!(best_distribution);
        opt = (termination_status(best_distribution) == MOI.OPTIMAL);
        loc_sol = (termination_status(best_distribution) == MOI.LOCALLY_SOLVED);
        #feasible = opt + loc_sol;
        finish_time_solve = Dates.Time(Dates.now());
        #print("Solving time: ")
        #println(finish_time_solve - start_time_solve)

        temp_dp_sum = value.(dispatch_sum)

    else
        aggre_max_transfer_opt = value.(aggre_max_transfer)
    end

    # If 1 customer at a node, easy to curtail least competitive bids - look at the max for each market pair, and curtail in order in capacities
    # Less obvious when multiple aggregators are at a node - makes no difference to the algorithm which aggregator is getting curtailed.
    # Objective function units is power - nodal max power
    new_trapeziums = deepcopy(trapeziums)
    for a in 1:n_aggs, i in 1:n_nodes
        for m_pair in [1, 5, 6, 7]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([value.(aggre_max_transfer_opt[a, i, gen]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        for m_pair in [4, 8, 9, 10]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([-value.(aggre_max_transfer_opt[a, i, load]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        # for m_pair in [2]
        #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        # end
        # for m_pair in [3]
        #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        # end
    end

    new_capacities = zeros(size(capacities))
    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];
    for a in 1:n_aggs, i in 1:n_nodes, m_gen in [1]#, 3, 4, 7, 8, 9]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_gen]) < value.(aggre_max_transfer_opt[a, i, gen])
                new_capacities[a,c,i,m_gen] = minimum([value.(aggre_max_transfer_opt[a, i, gen]) - sum(new_capacities[a,1:(c-1),i,m_gen]), capacities[a,c,i,m_gen]])
            end
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_load in [2]#, 5, 6, 10, 11, 12]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_load]) < -value.(aggre_max_transfer_opt[a, i, load])
                new_capacities[a,c,i,m_load] = minimum([-value.(aggre_max_transfer_opt[a, i, load]) - sum(new_capacities[a,1:(c-1),i,m_load]), capacities[a,c,i,m_load]])
            end
        end
    end
    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];
    new_capacities[:,:,:,2] = new_capacities[:,end:-1:1,:,2];

    new_capacities[:,:,:,3:12] = capacities[:,:,:,3:12]

    #return OPF_result(value.(aggre_max_transfer), [opt loc_sol], value.(vm), value.(0), value.(nodal_max_transfer), objective_value(network_sim), value.(0), new_trapeziums)  # aggre_reactive_power
    if reactive == 1
        if norm == 1
            desc = "Power l1 reactive   "
        end
        if norm == 2
            desc = "Power l2 reactive   "
        end
    else
        if norm == 1
            desc = "Power l1 no reactive"
        end
        if norm == 2
            desc = "Power l2 no reactive"
        end
    end

    if reactive == 1
        nd = naive_dispatch(desc, prices, bids, new_capacities, new_trapeziums, loss_factor, load_slice, pv_slice, 0)
    end

    #println("       - Simulating results")
    sb = naive_dispatch(desc, real_prices, bids, new_capacities, new_trapeziums, loss_factor, load_slice, pv_slice, 0)
    simulated_benefit = sb.objective

    if reactive == 0
        opf_data = OPF_data_new(description_input, objective_value(best_distribution), objective_value(network_sim), 
                            [opt_1 loc_sol_1], 0, value.(vm), nodal_max_transfer_values, 
                            value.(aggre_max_transfer_opt), value.(aggre_reactive_power), simulated_benefit, value.(I), sb.dispatch,
                            [value.(pg[1,1]), value.(pg[1,2])], solve_time(network_sim))
    else
        opf_data = OPF_data_new(description_input, nd.objective, objective_value(network_sim), 
                            [opt_1 loc_sol_1], 0, value.(vm), nodal_max_transfer_values, 
                            value.(aggre_max_transfer_opt), value.(aggre_reactive_power), simulated_benefit, value.(I), sb.dispatch,
                            [value.(pg[1,1]), value.(pg[1,2])], solve_time(network_sim))
    end
    return shaping_result(new_trapeziums, new_capacities, opf_data)
end

function naive_dispatch(description, prices, bids, capacities, trapeziums, loss_factor, load_slice, pv_slice, nodal_extreme_bid_powers)

    gen = 1
    load = 2
    energy_raise    = 1
    energy_lower    = 2
    n_markets = 12

    n_aggs  = size(trapeziums,1)
    n_bands = size(capacities,2)
    n_nodes = size(trapeziums,3)
    n_traps = size(trapeziums,4)

    trapezium_data = zeros(n_aggs, n_nodes, n_traps, 2, 2)
    for a in 1:n_aggs, i in 1:n_nodes, t in 1:n_traps
        trapezium_data[a,i,t,1,1] = trapeziums[a,1,i,t] / (trapeziums[a,4,i,t] - trapeziums[a,2,i,t])
        trapezium_data[a,i,t,1,2] = - trapeziums[a,2,i,t] * trapezium_data[a,i,t,1,1]
        trapezium_data[a,i,t,2,1] = - trapeziums[a,1,i,t] / (trapeziums[a,3,i,t] - trapeziums[a,5,i,t])
        trapezium_data[a,i,t,2,2] = - trapeziums[a,3,i,t] * trapezium_data[a,i,t,2,1]
    end

    n_scenarios   = length(prices.energy)
    probabilities = prices.probabilities
    #println("Number of scenarios: ",n_scenarios)

    prices_array = transpose([prices.energy prices.energy prices.raise_reg prices.lower_reg prices.raise_reg prices.lower_reg prices.raise_6_sec prices.raise_60_sec prices.raise_5_min prices.lower_6_sec prices.lower_60_sec prices.lower_5_min])
    agg_load_slice = sum(load_slice, dims=1)
    agg_pv_slice = sum(pv_slice, dims=1)

    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)

    @variable(network_sim, 0 <=        dispatch[a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= capacities[a,c,i,m])
    @variable(network_sim, 0 <=    dispatch_sum[a in 1:n_aggs,                 i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= sum(capacities[a,c,i,m] for c in 1:n_bands))

    @objective(network_sim, Max,
        sum(
            probabilities[s] * (

                prices_array[energy_raise,s] * sum(dispatch[a,c,i,energy_raise,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) * loss_factor
                - sum(bids[a,c,energy_raise] * dispatch[a,c,i,energy_raise,s]  for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)

                - prices_array[energy_lower,s] * sum(dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) / loss_factor
                + sum(bids[a,c,energy_lower] * dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)

                + sum(prices_array[reserve_market,s] * loss_factor * dispatch[a,c,i,reserve_market,s] 
                for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)

                - sum(bids[a,c,reserve_market] * dispatch[a,c,i,reserve_market,s] 
                for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)

            ) for s in 1:n_scenarios
        ) / 12 / 1000
    );


    @constraint(network_sim, d_sum[a in 1:n_aggs, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios],
                dispatch_sum[a, i, m, s] == sum(dispatch[a,c,i,m,s] for c in 1:n_bands))

    start_time_constraints = Dates.Time(Dates.now());

    # The following keys relate to trapezium vertices, not aggregagtors (a) or bands (b).
    a_max = 1;
    e_min = 2;
    e_max = 3;
    b_l   = 4;
    b_h   = 5;

    grad = 1
    offset = 2

    lower_slope = 1
    upper_slope = 2

    # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [3, 4],         s in 1:n_scenarios
        # Ramp 1 - (4, won't occur in market 3)     x=y markets
        if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0             # enablement min off zero
            @constraint(network_sim,              
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        <= 
                            # energy_below__reg_enablement[a, i, gen] *
                            (trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad] * dispatch_sum[a,i,gen,s] 
                                + trapezium_data[a,i,m_rel_to_gen-2,lower_slope,offset])
                            # +
                            # energy_beyond_reg_enablement[a, i, gen]
                            # * (0)
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_gen,s] <= trapeziums[a,a_max,i,m_rel_to_gen-2]
        )
        # Ramp 3 - (3, won't occur in market 4)     x+y=k markets
        if trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(network_sim,
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        <= 
                            # energy_below__reg_enablement[a, i, gen] *     # condition
                            (trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad] * dispatch_sum[a,i,gen,s] 
                                    + trapezium_data[a,i,m_rel_to_gen-2,upper_slope,offset]) # value
                            # +
                            # energy_beyond_reg_enablement[a, i, gen]      # condition
                            # * (0)        # value
            )
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [7, 8, 9],      s in 1:n_scenarios
        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0
            @constraint(network_sim, 
                        dispatch_sum[a,i,gen,s]     # Energy
                        - dispatch_sum[a,i,4,s]     # Regulation lower
                        - (1 / trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen,s]
                        <= trapeziums[a,e_max,i,m_rel_to_gen-2]
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_gen,s]
                    <= trapeziums[a,a_max,i,m_rel_to_gen-2]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2]) > 0
            @constraint(network_sim,
                        dispatch_sum[a,i,gen,s]     # Energy
                        + dispatch_sum[a,i,3,s]     # Regulation raise
                        - (1 / trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen, s]
                        <= trapeziums[a,e_max,i,m_rel_to_gen-2]
            )
        end
    end

    # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [5, 6],         s in 1:n_scenarios
        # Ramp 1 - (5, won't occur in market 6)     x=y markets
        if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0             # enablement min off zero
            @constraint(network_sim,              
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        <= 
                            # energy_below__reg_enablement[a, i, load] *
                            (trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad] * dispatch_sum[a,i,load,s] 
                                    + trapezium_data[a,i,m_rel_to_lower-2,lower_slope,offset])
                            # +
                            # energy_beyond_reg_enablement[a, i, load]
                            # * (0)
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_lower,s] <= trapeziums[a,a_max,i,m_rel_to_lower-2]
        )
        # Ramp 3 - (6, won't occur in market 5)     x+y=k markets
        if trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(network_sim,
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        <= 
                            # energy_below__reg_enablement[a, i, load] *
                            (trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad] * dispatch_sum[a,i,load,s] + trapezium_data[a,i,m_rel_to_lower-2,upper_slope,offset])
                            # +
                            # energy_beyond_reg_enablement[a, i, load]
                            # * (0)
            )
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [10, 11, 12],      s in 1:n_scenarios
        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0
            @constraint(network_sim, 
                        dispatch_sum[a,i,load,s]     # Energy
                        - dispatch_sum[a,i,5,s]     # Regulation lower
                        - (1 / trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                        <= trapeziums[a,e_max,i,m_rel_to_lower-2]
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_lower,s]
                    <= trapeziums[a,a_max,i,m_rel_to_lower-2]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2]) > 0
            @constraint(network_sim,
                        dispatch_sum[a,i,load,s]     # Energy
                        + dispatch_sum[a,i,6,s]     # Regulation raise
                        - (1 / trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                        <= trapeziums[a,e_max,i,m_rel_to_lower-2]
            )
        end
    end

    # Run and report
    start_time_solve = Dates.Time(Dates.now());
    status = JuMP.optimize!(network_sim);
    opt = (termination_status(network_sim) == MOI.OPTIMAL);
    loc_sol = (termination_status(network_sim) == MOI.LOCALLY_SOLVED);

    return naive_dispatch_data_new(description, value.(dispatch), objective_value(network_sim), nodal_extreme_bid_powers)
end

function ideal_dispatch(simparams, network, prices, bids, capacities, trapeziums, trapezium_data, reactive, extreme_bid_powers, nodal_extreme_bid_powers, description_input, loss_factor, curr_lims, load_slice, pv_slice)

    n_aggs =    size(bids, 1);                     real_prices = deepcopy(prices);
    n_bands =   size(bids, 2)
    n_nodes =   length(network.branch)+1;
    n_markets = size(bids, 3)

    gen = 1
    load = 2
    energy_raise    = 1
    energy_lower    = 2
    n_markets = 12

    n_scenarios   = length(prices.energy)
    probabilities = prices.probabilities
    #println("Number of scenarios: ",n_scenarios)

    prices_array = transpose([prices.energy prices.energy prices.raise_reg prices.lower_reg prices.raise_reg prices.lower_reg prices.raise_6_sec prices.raise_60_sec prices.raise_5_min prices.lower_6_sec prices.lower_60_sec prices.lower_5_min])
    agg_load_slice = load_slice; #sum(load_slice, dims=1)
    agg_pv_slice = pv_slice; #sum(pv_slice, dims=1)

    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)
    #set_optimizer_attribute(network_sim, "nlp_scaling_method", "none")

    # General variables
    @variable(network_sim, simparams.voltage_low <= vm[i in 1:n_nodes, d in [gen,load]] <= simparams.voltage_high)
    @variable(network_sim, -(curr_lims[l] / (100/12.66))^2 <= I[(l,i,j) in network.arcs, d in [gen,load]] <= (curr_lims[l] / (100/12.66))^2)
    @variable(network_sim, p[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, q[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, pg[i in keys(network.gen), d in [gen,load]]<=10000000*network.gen[i]["pmax"])
    @variable(network_sim, qg[i in keys(network.gen), d in [gen,load]])
    @variable(network_sim,   nodal_max_transfer[i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim,   aggre_max_transfer[a in 1:n_aggs,                 i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim, 0 <=        dispatch[a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= capacities[a,c,i,m])
    @variable(network_sim, 0 <=    dispatch_sum[a in 1:n_aggs,                 i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios] <= sum(capacities[a,c,i,m] for c in 1:n_bands))
    @variable(network_sim, aggre_reactive_power[a in 1:n_aggs,                 i in 1:n_nodes, d in [gen,load]])

    # Objective: Maximise aggregator welfare (max revenue less costs)
    @objective(network_sim, Max,
        sum(
            probabilities[s] * (

                prices_array[energy_raise,s] * sum(dispatch[a,c,i,energy_raise,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) * loss_factor
                - sum(bids[a,c,energy_raise] * dispatch[a,c,i,energy_raise,s]  for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)

                - prices_array[energy_lower,s] * sum(dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) / loss_factor
                + sum(bids[a,c,energy_lower] * dispatch[a,c,i,energy_lower,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)

                + sum(prices_array[reserve_market,s] * loss_factor * dispatch[a,c,i,reserve_market,s] 
                for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)

                - sum(bids[a,c,reserve_market] * dispatch[a,c,i,reserve_market,s] 
                for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes, reserve_market in 3:n_markets)

            ) for s in 1:n_scenarios
        ) / 12 / 1000
    );

    start_time_constraints = Dates.Time(Dates.now());

    @constraint(network_sim, d_sum[a in 1:n_aggs, i in 1:n_nodes, m in 1:n_markets, s in 1:n_scenarios],
                dispatch_sum[a, i, m, s] == sum(dispatch[a,c,i,m,s] for c in 1:n_bands))

    # Total transfer at a node is the sum of potential transfers at aggs
    @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in [gen, load]], 
        nodal_max_transfer[i, d] == sum(aggre_max_transfer[a,i,d] for a in 1:n_aggs)
    )

    @constraint(network_sim, cap_transfers_to_bids_gen[i in 1:n_nodes],                                 # Fine
        nodal_max_transfer[i, gen] <= nodal_extreme_bid_powers[i, gen]
    )
    
    @constraint(network_sim, cap_transfers_to_bids_load[i in 1:n_nodes],                                # Fine
        nodal_max_transfer[i, load] >= nodal_extreme_bid_powers[i, load]
    )   

    @constraint(network_sim, aggre_max_transfer_greater_than[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, load] <= aggre_max_transfer[a, i, gen])

    @constraint(network_sim, aggre_max_transfer_bounds_gen_upper[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, gen]  <= extreme_bid_powers[a, i, gen])
    @constraint(network_sim, aggre_max_transfer_bounds_load_upper[a in 1:n_aggs, i in 1:n_nodes],
        aggre_max_transfer[a, i, load] >= extreme_bid_powers[a, i, load])

    # The following keys relate to trapezium vertices, not aggregagtors (a) or bands (b).
    a_max = 1;
    e_min = 2;
    e_max = 3;
    b_l   = 4;
    b_h   = 5;

    grad = 1
    offset = 2

    lower_slope = 1
    upper_slope = 2

    ############
        # Flags to determine whether regulation services available
        # Sum to 1
        # @constraint(network_sim, energy_flag_sums[a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]], 
        #               energy_below__reg_enablement[a, i, d]
        #             + energy_beyond_reg_enablement[a, i, d] 
        #             == 1
        #             )
        # # Encode flag meanings
        # @constraint(network_sim, energy_reg_flag_gen[a in 1:n_aggs, i in 1:n_nodes, s in 1:n_scenarios], 
        #             energy_beyond_reg_enablement[a, i, gen] => {dispatch_sum[a,i,gen,s] >= trapeziums[a, e_max, i, 1]}
        #             )
        # @constraint(network_sim, energy_reg_flag_load[a in 1:n_aggs, i in 1:n_nodes, s in 1:n_scenarios], 
        #             energy_beyond_reg_enablement[a, i, load] => {dispatch_sum[a,i,gen,s] >= trapeziums[a, e_max, i, 4]}
        #             )

    # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [3, 4],         s in 1:n_scenarios
        # Ramp 1 - (4, won't occur in market 3)     x=y markets
        if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0             # enablement min off zero
            @constraint(network_sim,              
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        <= 
                        (trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad] * dispatch_sum[a,i,gen,s] 
                        + trapezium_data[a,i,m_rel_to_gen-2,lower_slope,offset])
            )
            @constraint(network_sim,
                       dispatch_sum[a,i,gen,s] <= aggre_max_transfer[a, i, gen]
            ) 
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_gen,s] <= trapeziums[a,a_max,i,m_rel_to_gen-2]
        )
        # Ramp 3 - (3, won't occur in market 4)     x+y=k markets
        if trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(network_sim,
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        <= 
                            # energy_below__reg_enablement[a, i, gen]     # condition
                            (trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad] * dispatch_sum[a,i,gen,s] 
                                    + trapezium_data[a,i,m_rel_to_gen-2,upper_slope,offset]) # value
                            # +
                            # energy_beyond_reg_enablement[a, i, gen]      # condition
                            # * (0)        # value
            )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_gen,s] + dispatch_sum[a,i,gen,s] 
                        <= aggre_max_transfer[a, i, gen]
            )
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_gen in  [7, 8, 9],      s in 1:n_scenarios
        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,m_rel_to_gen-2] - trapeziums[a,e_min,i,m_rel_to_gen-2] > 0
            @constraint(network_sim, 
                        dispatch_sum[a,i,gen,s]     # Energy
                        - dispatch_sum[a,i,4,s]     # Regulation lower
                        - (1 / trapezium_data[a,i,m_rel_to_gen-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen,s]
                        <= trapeziums[a,e_max,i,m_rel_to_gen-2]
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_gen,s]
                    <= trapeziums[a,a_max,i,m_rel_to_gen-2]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,m_rel_to_gen-2] - trapeziums[a,b_h,i,m_rel_to_gen-2]) > 0
            @constraint(network_sim,
                        dispatch_sum[a,i,gen,s]     # Energy
                        + dispatch_sum[a,i,3,s]     # Regulation raise
                        - (1 / trapezium_data[a,i,m_rel_to_gen-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_gen, s]
                        <= trapeziums[a,e_max,i,m_rel_to_gen-2]
            )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_gen,s]
                        + dispatch_sum[a,i,gen,s]
                        + dispatch_sum[a,i,3,s]
                        <= aggre_max_transfer[a, i, gen]
            )
        end
    end

    # Encode bid trapeziums for each agent - INDEXED TO 12 ENERGYGEN AND FCASRAISE
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [5, 6],         s in 1:n_scenarios
        # Ramp 1 - (5, won't occur in market 6)     x=y markets
        if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0             # enablement min off zero
            @constraint(network_sim,              
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        <= 
                        trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad] * dispatch_sum[a,i,load,s] 
                        + trapezium_data[a,i,m_rel_to_lower-2,lower_slope,offset]
            )
            @constraint(network_sim,
                       dispatch_sum[a,i,load,s] <= -aggre_max_transfer[a, i, load]
            ) 
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_lower,s] <= trapeziums[a,a_max,i,m_rel_to_lower-2]
        )
        # Ramp 3 - (6, won't occur in market 5)     x+y=k markets
        if trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2] > 0        # If there is a slope on the right hand side - excludes scenario from above. Cleaner conditioning possible
            @constraint(network_sim,
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        <= 
            #                 energy_below__reg_enablement[a, i, load]
                            (trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad] * dispatch_sum[a,i,load,s] + trapezium_data[a,i,m_rel_to_lower-2,upper_slope,offset])
            #                 +
            #                 energy_beyond_reg_enablement[a, i, load]
            #                 * (0)
            )
            # @constraint(network_sim,
            #             dispatch_sum[a,i,m_rel_to_lower,s]
            #             <=  
            #                 1/30 *  log(
            #                     1 + exp(
            #                         (-dispatch_sum[a,i,load,s] + trapeziums[a, e_max, i, load])*30
            #                     )
            #                 )
            # )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_lower,s] + dispatch_sum[a,i,load,s] 
                        <= -aggre_max_transfer[a, i, load]
            )
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_rel_to_lower in  [10, 11, 12],      s in 1:n_scenarios
        # Ramp 1 - ONLY FOR CROSS-REGULATION MARKETS
        if trapeziums[a,b_l,i,m_rel_to_lower-2] - trapeziums[a,e_min,i,m_rel_to_lower-2] > 0
            @constraint(network_sim, 
                        dispatch_sum[a,i,load,s]     # Energy
                        - dispatch_sum[a,i,5,s]     # Regulation raise
                        - (1 / trapezium_data[a,i,m_rel_to_lower-2,lower_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                        <= trapeziums[a,e_max,i,m_rel_to_lower-2]
            )
        end
        # Flat top 2
        @constraint(network_sim,              
                    dispatch_sum[a,i,m_rel_to_lower,s]
                    <= trapeziums[a,a_max,i,m_rel_to_lower-2]
        )
        # Ramp 3
        if (trapeziums[a,e_max,i,m_rel_to_lower-2] - trapeziums[a,b_h,i,m_rel_to_lower-2]) > 0
            @constraint(network_sim,
                        dispatch_sum[a,i,load,s]     # Energy
                        + dispatch_sum[a,i,6,s]     # Regulation lower
                        - (1 / trapezium_data[a,i,m_rel_to_lower-2,upper_slope,grad]) * dispatch_sum[a, i, m_rel_to_lower,s]
                        <= trapeziums[a,e_max,i,m_rel_to_lower-2]
            )
            @constraint(network_sim, 
                        dispatch_sum[a,i,m_rel_to_lower,s]
                        + dispatch_sum[a,i,load,s]
                        + dispatch_sum[a,i,6,s]
                        <= -aggre_max_transfer[a, i, load]
            )
        end
    end

    # CHOOSE HOW TO DETERMINE MAX POWER
    # In reactive off case, this constraint seems to be binding
    if reactive == 1
        if reactive_power_norm == 1
            for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
        #     @NLconstraint(network_sim,  aggre_reactive_power[a, i, d]^2 + aggre_max_transfer[a, i, d]^2 <= extreme_bid_powers[a,i,d]^2)
                @constraint(network_sim,    aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] <= extreme_bid_powers[a,i,1])                       # on its own this stuffs everything up
                @constraint(network_sim,  - aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] <= - extreme_bid_powers[a,i,2])                   # somehow procludes zero reactive
                @constraint(network_sim,  - aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] >= - extreme_bid_powers[a,i,1])              
                @constraint(network_sim,    aggre_max_transfer[a,i,d] + aggre_reactive_power[a,i,d] >= extreme_bid_powers[a,i,2])

                # in our case, en_gen capacities are always greater than en_load, so:
                #@constraint(network_sim,    aggre_max_transfer[a,i,d] <= extreme_bid_powers[a,i,1])
                @constraint(network_sim,    aggre_reactive_power[a,i,d] >= extreme_bid_powers[a,i,2])                                                   # on their own, these 2 better than no reac
                @constraint(network_sim,    aggre_reactive_power[a,i,d] <= extreme_bid_powers[a,i,1])                                                   # makes sense, consistent with 0 in no reac

            end
        end
        if reactive_power_norm == 2
            for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
                @NLconstraint(network_sim,  aggre_reactive_power[a, i, d]^2 + aggre_max_transfer[a, i, d]^2 <= extreme_bid_powers[a,i,d]^2)                                              # makes sense, consistent with 0 in no reac
            end
        end
    end

    # SWITCH TO ACTIVE POWER ONLY
    if reactive == 0
        for a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]
            @constraint(network_sim, aggre_reactive_power[a, i, d] == 0)
        end
    end

    # Branch flow model
    bfm = 1
    if bfm == 1
        # BRANCH FLOW MODEL
        # Kirchoff constraints - real power
        @constraint(network_sim, high[i in 1:n_nodes, d in [gen,load]],
            sum(p[a,d] for a in network.bus_arcs[i]["to"])
            - sum((network.line_char[a]["br_r"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"]) 
            + sum(pg[g,d] for g in network.bus_gens[i])
            + (nodal_max_transfer[i,d] - agg_load_slice[i] - agg_pv_slice[i]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Kirchoff constraints - reactive power
        @constraint(network_sim, reac[i in 1:n_nodes, d in [gen,load]],
            sum(q[a,d] for a in network.bus_arcs[i]["to"] )
            - sum((network.line_char[a]["br_x"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"] ) 
            + sum(qg[g,d] for g in network.bus_gens[i])
            + sum(aggre_reactive_power[a,i,d] for a in 1:n_aggs) / simparams.sbase                  # + reactive power support here
            == sum(q[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Initial conditions
        @constraint(network_sim, top_voltage_high_gen,  vm[1,gen] ==1)
        @constraint(network_sim, top_voltage_high_load, vm[1,load]==1)
        # Voltage steps across branch as function of powers and current - gen scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,gen]
            q_fr = q[f_idx,gen]
            I_fr = I[f_idx,gen]
            vm_fr = vm[br["f_bus"],gen]
            vm_to = vm[br["t_bus"],gen]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
        # Voltage steps across branch as function of powers and current - load scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,load]
            q_fr = q[f_idx,load]
            I_fr = I[f_idx,load]
            vm_fr = vm[br["f_bus"],load]
            vm_to = vm[br["t_bus"],load]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
    end

    finish_time_constraints = Dates.Time(Dates.now());
    #print("Constraints time: ")
    #println(finish_time_constraints - start_time_constraints)

    # Run and report
    start_time_solve = Dates.Time(Dates.now());
    #println(start_time_solve)
    status = JuMP.optimize!(network_sim);
    opt = (termination_status(network_sim) == MOI.OPTIMAL);
    loc_sol = (termination_status(network_sim) == MOI.LOCALLY_SOLVED);
    #feasible = opt + loc_sol;
    finish_time_solve = Dates.Time(Dates.now());

    dp_vals = value.(dispatch);
    tight_aggre_max_transfer_scen = zeros(3, 69, 2, n_scenarios);
    for a in 1:n_aggs, i in 1:n_nodes, d in [1,2], s in 1:n_scenarios
        tight_aggre_max_transfer_scen[a, i, 1, s] = maximum(      sum(dp_vals[a,c,i,m,s] for c in 1:10, m in m_pair)     for m_pair in [[1,3,7],  [1,3,8],  [1,3,9]])
        tight_aggre_max_transfer_scen[a, i, 2, s] = maximum(      sum(dp_vals[a,c,i,m,s] for c in 1:10, m in m_pair)     for m_pair in [[2,6,10], [2,6,11], [2,6,12]])
    end

    tight_aggre_max_transfer = maximum(tight_aggre_max_transfer_scen, dims=4);
    tight_aggre_max_transfer[:,:,2] = -tight_aggre_max_transfer[:,:,2]
    # ready to sub in the below for new trapeium calculation
    
    # uncomment for tight aggregator transfer bounds
    aggre_max_transfer = tight_aggre_max_transfer;

    new_trapeziums = deepcopy(trapeziums)
    for a in 1:n_aggs, i in 1:n_nodes
        for m_pair in [1, 5, 6, 7]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer[a, i, gen])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer[a, i, gen])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([value.(aggre_max_transfer[a, i, gen]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        for m_pair in [4, 8, 9, 10]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer[a, i, load])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer[a, i, load])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([-value.(aggre_max_transfer[a, i, load]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        # Following can be commented out because trapezium shouldn't require changing if energy capacity is limited
            # for m_pair in [2]
            #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], value.(aggre_max_transfer[a, i, gen])])
            # end
            # for m_pair in [3]
            #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], -value.(aggre_max_transfer[a, i, load])])
            # end
    end

    ######
    # NEEDS SERIOUS RE-DOING
    new_capacities = zeros(size(capacities))
    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];

    for a in 1:n_aggs, i in 1:n_nodes, m_gen in [1]#, 3, 4, 7, 8, 9]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_gen]) < value.(aggre_max_transfer[a, i, gen])
                new_capacities[a,c,i,m_gen] = minimum([value.(aggre_max_transfer[a, i, gen]) - sum(new_capacities[a,1:(c-1),i,m_gen]), capacities[a,c,i,m_gen]])
            end
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_load in [2]#, 5, 6, 10, 11, 12]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_load]) < -value.(aggre_max_transfer[a, i, load])
                new_capacities[a,c,i,m_load] = minimum([-value.(aggre_max_transfer[a, i, load]) - sum(new_capacities[a,1:(c-1),i,m_load]), capacities[a,c,i,m_load]])
            end
        end
    end

    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];
    new_capacities[:,:,:,2] = new_capacities[:,end:-1:1,:,2];

    new_capacities[:,:,:,3:12] = capacities[:,:,:,3:12]

    if reactive == 1
        desc = "Stoch reactive      "
    else
        desc = "Stoch no reactive   "
    end

    # capped_capacities_1 = maximum(value.(dispatch), dims=5)
    # new_capacities = capped_capacities_1[:,:,:,:,1]

    #println(objective_value(network_sim))
    sb = naive_dispatch(description_input, real_prices, bids, new_capacities, new_trapeziums, loss_factor, load_slice, pv_slice, 0)
    simulated_benefit = sb.objective
    #println(simulated_benefit)
    #println("Sim benefit: ", simulated_benefit)

    #println("Currents: ", value.(p))

    opf_data = OPF_data_new(description_input, objective_value(network_sim), 0, 
                [opt loc_sol], value.(dispatch), value.(vm), value.(nodal_max_transfer), 
                value.(aggre_max_transfer), value.(aggre_reactive_power), simulated_benefit, value.(I), sb.dispatch,
                [value.(pg[1,1]), value.(pg[1,2])], solve_time(network_sim))

    return shaping_result(new_trapeziums, new_capacities, opf_data)
end

function equal_envelopes(simparams, network, real_prices, bids, capacities, trapeziums, description_input, curr_lims, prosumer_composition, factor, loss_factor, max_loads)

    #prosumer_composition[node][agg] = n_custs
    customer_matrix = zeros(69,3)
    load_customer_matrix = zeros(69,3)
    for a in 1:3, i in 1:69
        customer_matrix[i,a]       = prosumer_composition[i][a]["prosumers"] * factor
        load_customer_matrix[i,a]  = prosumer_composition[i][a]["prosumers"] * factor * 1.5
    end

    #print(customer_matrix)
    #print(load_customer_matrix)

    # Index variables for clarity
    n_aggs =    size(bids, 1)
    n_bands =   size(bids, 2)
    n_nodes =   length(network.branch)+1;
    n_markets = size(bids, 3)
    gen =       1
    load =      2
    n_markets = 12

    # Declare model
    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)

    # General variables
    @variable(network_sim, simparams.voltage_low <= vm[i in 1:n_nodes, d in [gen,load]] <= simparams.voltage_high)
    @variable(network_sim, -(curr_lims[l] / (100/12.66))^2 <= I[(l,i,j) in network.arcs, d in [gen,load]] <= (curr_lims[l] / (100/12.66))^2)
    @variable(network_sim, p[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, q[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, pg[i in keys(network.gen), d in [gen,load]]<=10000000*network.gen[i]["pmax"])
    @variable(network_sim, qg[i in keys(network.gen), d in [gen,load]])
    @variable(network_sim,                  nodal_max_transfer[i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim,   aggre_max_transfer[a in 1:n_aggs, i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim, aggre_reactive_power[a in 1:n_aggs, i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim, connection_point_bounds[d in [gen,load]])

    @constraint(network_sim, connection_point_bounds[gen]   >= 0)
    @constraint(network_sim, connection_point_bounds[load]  <= 0)

    @constraint(network_sim, setting_boundaries[a in 1:n_aggs, i in 1:n_nodes, d in [gen, load]], 
                aggre_max_transfer[a, i, d] == customer_matrix[i,a] * connection_point_bounds[d])

    ###################
    @objective(network_sim, Max, connection_point_bounds[gen] - connection_point_bounds[load]);
    ###################

    start_time_constraints = Dates.Time(Dates.now());

    # Total transfer at a node is the sum of potential transfers at aggs
    @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in [gen, load]], 
        nodal_max_transfer[i, d] == sum(aggre_max_transfer[a,i,d] for a in 1:n_aggs)
    )

    # Branch flow model
    bfm = 1
    if bfm == 1
        # BRANCH FLOW MODEL
        # Kirchoff constraints - real power
        @constraint(network_sim, high[i in 1:n_nodes, d in [gen]],
            sum(p[a,d] for a in network.bus_arcs[i]["to"])
            - sum((network.line_char[a]["br_r"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"]) 
            + sum(pg[g,d] for g in network.bus_gens[i])
            + (nodal_max_transfer[i,d]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
            # nodal_max_transfer[i,d]
        )

        @constraint(network_sim, low[i in 1:n_nodes, d in [load]],
            sum(p[a,d] for a in network.bus_arcs[i]["to"])
            - sum((network.line_char[a]["br_r"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"]) 
            + sum(pg[g,d] for g in network.bus_gens[i])
            + (nodal_max_transfer[i,d] - max_loads[i]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
        )

        # Kirchoff constraints - reactive power
        @constraint(network_sim, reac[i in 1:n_nodes, d in [gen,load]],
            sum(q[a,d] for a in network.bus_arcs[i]["to"] )
            - sum((network.line_char[a]["br_x"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"] ) 
            + sum(qg[g,d] for g in network.bus_gens[i])
            + sum(aggre_reactive_power[a,i,d] for a in 1:n_aggs)*0 / simparams.sbase                  # + reactive power support here
            == sum(q[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Initial conditions
        @constraint(network_sim, top_voltage_high_gen,  vm[1,gen] ==1)
        @constraint(network_sim, top_voltage_high_load, vm[1,load]==1)
        # Voltage steps across branch as function of powers and current - gen scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,gen]
            q_fr = q[f_idx,gen]
            I_fr = I[f_idx,gen]
            vm_fr = vm[br["f_bus"],gen]
            vm_to = vm[br["t_bus"],gen]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
        # Voltage steps across branch as function of powers and current - load scenario
        for (i,br) in network.branch
            f_idx = (i, br["f_bus"], br["t_bus"])
            p_fr = p[f_idx,load]
            q_fr = q[f_idx,load]
            I_fr = I[f_idx,load]
            vm_fr = vm[br["f_bus"],load]
            vm_to = vm[br["t_bus"],load]

            @constraint(network_sim, vm_fr - vm_to 
                == 2*((br["br_r"]/simparams.zbase)*p_fr 
                + (br["br_x"]/simparams.zbase)*q_fr)  
                - ((br["br_r"]/simparams.zbase)^2+(br["br_x"]/simparams.zbase)^2)*I_fr 
            )
            @NLconstraint(network_sim, I_fr*vm_fr == p_fr^2+q_fr^2)
        end
    end

    finish_time_constraints = Dates.Time(Dates.now());
    #print("Constraints time: ")
    #println(finish_time_constraints - start_time_constraints)

    # Run and report
    start_time_solve = Dates.Time(Dates.now());
    #println(start_time_solve)
    status = JuMP.optimize!(network_sim);
    opt = (termination_status(network_sim) == MOI.OPTIMAL);
    loc_sol = (termination_status(network_sim) == MOI.LOCALLY_SOLVED);
    #feasible = opt + loc_sol;
    finish_time_solve = Dates.Time(Dates.now());
    #print("Solving time: ")
    #println(finish_time_solve - start_time_solve)

    #println(value.(connection_point_bounds))

    # This determines nodal max power power_flows
    # Now create an optimisation problem which determines best aggre_max_transfers maximising aggregator benefit

    nodal_max_transfer_values = value.(nodal_max_transfer)

    aggre_max_transfer_opt = value.(aggre_max_transfer)

    # If 1 customer at a node, easy to curtail least competitive bids - look at the max for each market pair, and curtail in order in capacities
    # Less obvious when multiple aggregators are at a node - makes no difference to the algorithm which aggregator is getting curtailed.
    # Objective function units is power - nodal max power
    new_trapeziums = deepcopy(trapeziums)
    for a in 1:n_aggs, i in 1:n_nodes
        for m_pair in [1, 5, 6, 7]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([value.(aggre_max_transfer_opt[a, i, gen]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        for m_pair in [4, 8, 9, 10]
            new_trapeziums[a, 1, i, m_pair] = maximum([minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])]), 0])
            new_trapeziums[a, 3, i, m_pair] = maximum([minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])]), 0])
            new_trapeziums[a, 5, i, m_pair] = minimum([maximum([-value.(aggre_max_transfer_opt[a, i, load]) - trapeziums[a, 1, i, m_pair], 0]), trapeziums[a, 5, i, m_pair]])
        end
        # for m_pair in [2]
        #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], value.(aggre_max_transfer_opt[a, i, gen])])
        # end
        # for m_pair in [3]
        #     new_trapeziums[a, 1, i, m_pair] = minimum([trapeziums[a, 1, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        #     new_trapeziums[a, 3, i, m_pair] = minimum([trapeziums[a, 3, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        #     new_trapeziums[a, 4, i, m_pair] = minimum([trapeziums[a, 4, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        #     new_trapeziums[a, 5, i, m_pair] = minimum([trapeziums[a, 5, i, m_pair], -value.(aggre_max_transfer_opt[a, i, load])])
        # end
    end

    new_capacities = zeros(size(capacities))
    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];
    for a in 1:n_aggs, i in 1:n_nodes, m_gen in [1]#, 3, 4, 7, 8, 9]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_gen]) < value.(aggre_max_transfer_opt[a, i, gen])
                new_capacities[a,c,i,m_gen] = minimum([value.(aggre_max_transfer_opt[a, i, gen]) - sum(new_capacities[a,1:(c-1),i,m_gen]), capacities[a,c,i,m_gen]])
            end
        end
    end
    for a in 1:n_aggs, i in 1:n_nodes, m_load in [2]#, 5, 6, 10, 11, 12]
        for c in 1:n_bands
            if sum(new_capacities[a,1:(c-1),i,m_load]) < -value.(aggre_max_transfer_opt[a, i, load])
                new_capacities[a,c,i,m_load] = minimum([-value.(aggre_max_transfer_opt[a, i, load]) - sum(new_capacities[a,1:(c-1),i,m_load]), capacities[a,c,i,m_load]])
            end
        end
    end
    capacities[:,:,:,2]     = capacities[:,end:-1:1,:,2];
    new_capacities[:,:,:,2] = new_capacities[:,end:-1:1,:,2];

    new_capacities[:,:,:,3:12] = capacities[:,:,:,3:12]

    #return OPF_result(value.(aggre_max_transfer), [opt loc_sol], value.(vm), value.(0), value.(nodal_max_transfer), objective_value(network_sim), value.(0), new_trapeziums)  # aggre_reactive_power

    #println("       - Simulating results")
    sb = naive_dispatch(description_input, real_prices, bids, new_capacities, new_trapeziums, loss_factor, [0], [0], 0)
    simulated_benefit = sb.objective

    opf_data = OPF_data_new(description_input, simulated_benefit, 0, 
                        [opt loc_sol], 0, value.(vm), nodal_max_transfer_values, 
                        value.(aggre_max_transfer_opt), value.(aggre_reactive_power), simulated_benefit, value.(I), sb.dispatch,
                        [value.(pg[1,1]), value.(pg[1,2])], solve_time(network_sim))

    return shaping_result(new_trapeziums, new_capacities, opf_data), value.(connection_point_bounds[gen]), value.(connection_point_bounds[load])
end

