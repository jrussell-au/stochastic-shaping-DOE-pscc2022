# Network evaluation and power flow functions
function naive_dispatch_with_network(simparams, network, nodal_extreme_bid_powers, load_slice, pv_slice)

    n_nodes =   length(network.branch)+1;

    gen = 1
    load = 2

    #println("Number of scenarios: ",n_scenarios)
    agg_load_slice = load_slice; #sum(load_slice, dims=1)
    agg_pv_slice = pv_slice; #sum(pv_slice, dims=1)

    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)
    #set_optimizer_attribute(network_sim, "nlp_scaling_method", "none")

    # General variables
    @variable(network_sim, vm[i in 1:n_nodes, d in [gen,load]])
    @variable(network_sim, I[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, p[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, q[(l,i,j) in network.arcs, d in [gen,load]])
    @variable(network_sim, pg[i in keys(network.gen), d in [gen,load]]<=10000000*network.gen[i]["pmax"])
    @variable(network_sim, qg[i in keys(network.gen), d in [gen,load]])

    # Objective: Maximise aggregator welfare (max revenue less costs)
    @objective(network_sim, Max,
        sum(0) / 12 / 1000
    );

    # Branch flow model
    bfm = 1
    if bfm == 1
        # BRANCH FLOW MODEL
        # Kirchoff constraints - real power
        @constraint(network_sim, high[i in 1:n_nodes, d in [gen,load]],
            sum(p[a,d] for a in network.bus_arcs[i]["to"])
            - sum((network.line_char[a]["br_r"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"]) 
            + sum(pg[g,d] for g in network.bus_gens[i])
            + (nodal_extreme_bid_powers[i,d] - agg_load_slice[i] - agg_pv_slice[i]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Kirchoff constraints - reactive power
        @constraint(network_sim, reac[i in 1:n_nodes, d in [gen,load]],
            sum(q[a,d] for a in network.bus_arcs[i]["to"] )
            - sum((network.line_char[a]["br_x"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"] ) 
            + sum(qg[g,d] for g in network.bus_gens[i])
            + 0 / simparams.sbase                  # + reactive power support here
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

    return value.(vm), value.(I), value.(pg[1,:])
end

function pf_for_loss_estimate(simparams, network, dispatch, curr_lims, load_slice, pv_slice, bids)

    n_aggs =    size(bids, 1)
    n_bands =   size(bids, 2)
    n_nodes =   length(network.branch)+1;

    gen = 1
    agg_load_slice = load_slice; #sum(load_slice, dims=1)
    agg_pv_slice = pv_slice; #sum(pv_slice, dims=1)

    #println("Number of scenarios: ",n_scenarios)

    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)
    #set_optimizer_attribute(network_sim, "nlp_scaling_method", "none")

    # General variables
    @variable(network_sim, simparams.voltage_low <= vm[i in 1:n_nodes, d in [gen]] <= simparams.voltage_high)
    @variable(network_sim, -(curr_lims[l] / (100/12.66))^2 <= I[(l,i,j) in network.arcs, d in [gen]] <= (curr_lims[l] / (100/12.66))^2)
    @variable(network_sim, p[(l,i,j) in network.arcs, d in [gen]])
    @variable(network_sim, q[(l,i,j) in network.arcs, d in [gen]])
    @variable(network_sim, pg[i in keys(network.gen), d in [gen]]<=10000000*network.gen[i]["pmax"])
    @variable(network_sim, qg[i in keys(network.gen), d in [gen]])
    @variable(network_sim, nodal_transfer[i in 1:n_nodes, d in [gen]])

    # Objective: Maximise aggregator welfare (max revenue less costs)
    @objective(network_sim, Max,
        # loss / some transfer quantity
        (pg[1,1] * simparams.sbase + sum(dispatch[:,:,:,1,1]) - sum(pv_slice) - sum(dispatch[:,:,:,2,1]) - sum(load_slice))      # net loss
        # / 
        # (pg[1,1] * simparams.sbase)
    );

    dispatch_sum = zeros(n_aggs, n_nodes, 2, 1)
    for a in 1:n_aggs, i in 1:n_nodes, m in 1:2, s in [1]
        dispatch_sum[a, i, m, s] = sum(dispatch[a, c, i, m, s] for c in 1:n_bands)
    end

    # Total transfer at a node is the sum of potential transfers at aggs
    @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in [gen]], 
        nodal_transfer[i, d] == sum(dispatch_sum[a,i,1,1] - dispatch_sum[a,i,2,1] for a in 1:n_aggs)
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
            + (nodal_transfer[i,d] - agg_load_slice[i] - agg_pv_slice[i]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Kirchoff constraints - reactive power
        @constraint(network_sim, reac[i in 1:n_nodes, d in [gen]],
            sum(q[a,d] for a in network.bus_arcs[i]["to"] )
            - sum((network.line_char[a]["br_x"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"] ) 
            + sum(qg[g,d] for g in network.bus_gens[i])
            + 0 / simparams.sbase                  # + reactive power support here
            == sum(q[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Initial conditions
        @constraint(network_sim, top_voltage_high_gen,  vm[1,gen] ==1)
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

    #println(value.(pg[1,1]))

    #println(objective_value(network_sim))
    #println(simulated_benefit)
    #println("Sim benefit: ", simulated_benefit)

    injection =     value.(pg[1,1]) * simparams.sbase                   # power in
    gen_total =     sum(dispatch[:,:,:,1,1])  - sum(agg_pv_slice)       # power generated
    load_total =    sum(dispatch[:,:,:,2,1])  + sum(agg_load_slice)     # power load

    #println("Quadratic values")
    a = gen_total
    b = injection
    c = - load_total

    # println("\na is ", a, " and of type ", typeof(a))
    # println("b is ", b, " and of type ", typeof(b))
    # println("c is ", c, " and of type ", typeof(c))

    println("\nNet import is ", injection)
    println("Total generation is ", gen_total)
    println("Total consumption is ", load_total)

    if abs(gen_total) > 1e-3
        x1 = (-b + sqrt(b^2 - 4*a*c))/(2*a)
    else
        x1 = load_total / injection
    end

    #print("x1 is ", x1, " and of type ", typeof(x1))

    #print(objective_value(network_sim))

    return x1#1 - (objective_value(network_sim) ./ abs.(value.(pg[1,1] * simparams.sbase)))
end


function pf_for_network_eval(simparams, network, dispatch, load_slice, pv_slice, bids, markets, nodal_extremes)

    n_aggs =    size(bids, 1)
    n_bands =   size(bids, 2)
    n_nodes =   length(network.branch)+1;

    gen = 1
    agg_load_slice = load_slice; #sum(load_slice, dims=1)
    agg_pv_slice = pv_slice; #sum(pv_slice, dims=1)

    #println("Number of scenarios: ",n_scenarios)

    network_sim  = Model(Ipopt.Optimizer)
    set_optimizer_attribute(network_sim, "print_level", 0)
    #set_optimizer_attribute(network_sim, "nlp_scaling_method", "none")

    # General variables
    @variable(network_sim, vm[i in 1:n_nodes, d in [gen]])
    @variable(network_sim, I[(l,i,j) in network.arcs, d in [gen]])
    @variable(network_sim, p[(l,i,j) in network.arcs, d in [gen]])
    @variable(network_sim, q[(l,i,j) in network.arcs, d in [gen]])
    @variable(network_sim, pg[i in keys(network.gen), d in [gen]])
    @variable(network_sim, qg[i in keys(network.gen), d in [gen]])
    @variable(network_sim, nodal_transfer[i in 1:n_nodes, d in [gen]])

    # Objective: Maximise aggregator welfare (max revenue less costs)
    @objective(network_sim, Max,
        # loss / some transfer quantity
        sum(0)      # snet loss
        # / 
        # (pg[1,1] * simparams.sbase)
    );

    if markets == "energy"
        dispatch_sum = zeros(n_aggs, n_nodes, 12, 1)
        for a in 1:n_aggs, i in 1:n_nodes, m in [1:12], s in [1]
            dispatch_sum[a, i, m, s] = sum(dispatch[a, c, i, m, s] for c in 1:n_bands)
        end
        @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in [gen]], 
            nodal_transfer[i, d] == sum(dispatch_sum[a,i,1,1] - dispatch_sum[a,i,2,1] for a in 1:n_aggs)
        )
    end
    if markets == "extreme_gen"
        @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in 1], 
            nodal_transfer[i, d] == nodal_extremes[i, 1]
        )
    end
    if markets == "extreme_load"
        @constraint(network_sim, agg_sum_max_transfers[i in 1:n_nodes, d in 1], 
            nodal_transfer[i, d] == nodal_extremes[i, 2]
        )
    end

    # Branch flow model
    bfm = 1
    if bfm == 1
        # BRANCH FLOW MODEL
        # Kirchoff constraints - real power
        @constraint(network_sim, high[i in 1:n_nodes, d in [gen]],
            sum(p[a,d] for a in network.bus_arcs[i]["to"])
            - sum((network.line_char[a]["br_r"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"]) 
            + sum(pg[g,d] for g in network.bus_gens[i])
            + (nodal_transfer[i,d] - agg_load_slice[i] - agg_pv_slice[i]) / simparams.sbase
            == sum(p[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Kirchoff constraints - reactive power
        @constraint(network_sim, reac[i in 1:n_nodes, d in [gen]],
            sum(q[a,d] for a in network.bus_arcs[i]["to"] )
            - sum((network.line_char[a]["br_x"]/simparams.zbase)*I[a,d] for a in network.bus_arcs[i]["to"] ) 
            + sum(qg[g,d] for g in network.bus_gens[i])
            + 0 / simparams.sbase                  # + reactive power support here
            == sum(q[a,d] for a in network.bus_arcs[i]["from"])
        )
        # Initial conditions
        @constraint(network_sim, top_voltage_high_gen,  vm[1,gen] ==1)
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

    return value.(vm), value.(I), value.(pg)
end







