# Analysis, visualization, and serialization functions
using Serialization

###############      ANALYSIS FUNCTIONS        ###############
function nodal_power_bounds(curts)

    power_bounds = zeros(69,length(curts)+1)
    for i in 1:69
        for n_c in 1:length(curts)
            power_bounds[i, n_c] = curts[n_c].OPF_data.nodal_max_transfer[i, 2]
        end
        power_bounds[i, length(curts)+1] = nodal_extreme_bid_powers[i, 2]
    end
    print("At node 1, bounds are ",power_bounds[1,:])
    return(power_bounds)
end

function plot_nodal_power_bounds(curts)

    power_bounds = nodal_power_bounds(curts)
    labs = String[]
    for n_curt in 1:length(curts)
        labs = push!(labs, curts[n_curt].OPF_data.description)
    end
    labs = push!(labs, "Requested exchange")
    labs = permutedims(labs)
    plot(power_bounds, xlabel="Node", ylabel="Active power allowance", legend=false)#labels=labs)

end

function voltage_bounds(curts)
    voltage_bounds = zeros(69,length(curts))
    for i in 1:69
        for n_c in 1:length(curts)
            voltage_bounds[i, n_c] =   curts[n_c].OPF_data.voltages[i, 1]
        end
    end
    print("At node 27, bounds are ",voltage_bounds[27,:])
    return(voltage_bounds)
end

function plot_voltage_bounds(curts)

    voltage_bounds_array = voltage_bounds(curts)
    labs = String[]
    for n_curt in 1:length(curts)
        labs = push!(labs, curts[n_curt].OPF_data.description)
    end
    labs = permutedims(labs)
    plot(voltage_bounds_array, xlabel="Node", ylabel="Extreme permissible voltage", labels=labs)

end

function plot_trapezium(trapeziums, agg, node, market)
    if market == 3
        mk = "Raise Reg Gen"
    end
    if market == 4
        mk = "Lower Reg Gen"
    end
    if market == 5
        mk = "Raise Reg Load"
    end
    if market == 6
        mk = "Lower Reg Load"
    end
    if market == 7
        mk = "Raise 6s"
    end
    if market == 8
        mk = "Raise 60s"
    end
    if market == 9
        mk = "Raise 5m"
    end
    if market == 10
        mk = "Lower 6s"
    end
    if market == 11
        mk = "Lower 60s"
    end
    if market == 12
        mk = "Lower 5m"
    end
    plot(trapeziums[agg, [2, 4, 5, 3], node, market], transpose([0 trapeziums[agg, 1, node, market] trapeziums[agg, 1, node, market] 0]),
    title=string("agg=",agg,", ","node=",node,", ","market=",market),
    xlabel="Energy (kW)", ylabel=mk,
    legend=false)
end

function compare_capacities_and_trapeziums(curtailment_1, curtailment_2)
    capacity_differences = curtailment_1.capacities - curtailment_2.capacities
    capacity_differences_pos = (capacity_differences .* (capacity_differences .> 0))
    capacity_differences_neg = (capacity_differences .* (capacity_differences .< 0))
    sum_pos = sum(capacity_differences_pos)
    sum_neg = sum(capacity_differences_neg)
    trapezium_differences = curtailment_1.trapeziums - curtailment_2.trapeziums
    breakpoint_differences = abs.(trapezium_differences[:,5,:,:])

    println("----------------------------------------------------------------------------------------------------------------------------------------------")
    println("Capacities")
    println("Positive differences:        Maximum:    ", round(maximum(capacity_differences_pos), digits=3), "     Sum:    ", round(sum_pos,digits=3), "     (",round(sum_pos/sum(curtailment_1.capacities),digits=3)," %)")
    println("Negative differences:        Maximum:    ", round(minimum(capacity_differences_neg), digits=3), "     Sum:    ", round(sum_neg,digits=3), "     (",round(sum_neg/sum(curtailment_1.capacities),digits=3)," %)")
    println("\nTrapeziums")
    println("Raise breakpoint reductions:       Maximum:    ", round(maximum(breakpoint_differences[:,:,[1,2,5,6,7]]),digits=3),  "     Sum:    ", round(sum(breakpoint_differences[:,:,[1,2,5,6,7]]), digits=3))
    println("Lower breakpoint reductions:       Maximum:    ", round(maximum(breakpoint_differences[:,:,[3,4,8,9,10]]),digits=3), "     Sum:    ", round(sum(breakpoint_differences[:,:,[3,4,8,9,10]]), digits=3))
    println("\nObjectives")
    println("Objective 1:     ", round(curtailment_1.OPF_data.objective_b, digits=3),"     Objective 2:     ", round(curtailment_2.OPF_data.objective_b, digits=3),"     Benefit 1 over 2: ", round((curtailment_1.OPF_data.objective_b / curtailment_2.OPF_data.objective_b - 1)*100, digits=3), " %")
end

function list_curts(list)
    if typeof(list[1]) == naive_dispatch_data
        for c in 1:length(list)
            println(string(c), " - ", list[c].description)
        end    
    else
        for c in 1:length(list)
            println(string(c), " - ", list[c].OPF_data.description, "\nExpected benefit:   ", list[c].OPF_data.objective_b, "\nSimulated benefit:  ", list[c].OPF_data.simulated_benefit)
        end    
    end
end

function long_term_benefits(list, base_for_plotting)

    benefits = zeros(length(list[1]))
    names_ = []
    for n_type in 1:length(list[1])
        push!(names_, list[1][n_type].OPF_data.description)
        for time in 1:length(list)
            if time == 9999999
                0
            else
                benefits[n_type] = benefits[n_type] + list[time][n_type].OPF_data.simulated_benefit
            end
        end
    end

    print("Benefits are: ", benefits)
    display(benefits)

    if base_for_plotting == "rel"
        to_plot = benefits .- benefits[end]
    end
    if base_for_plotting == "abs"
        to_plot = benefits
    end

    bar(to_plot, xticks=(1:length(names_), names_), legend=false, xrotation =20, ylabel="Benefit")

end

function display_benefits(listc, listn, time, type)

    curts = listc[time]
    naive = listn[time].NDD
    if type == "exp"
        bs = zeros(length(curts)+1)
        bs[1] = naive.objective
        println("Benefit without constraints:               ", naive.objective)
        for c in 1:length(curts)
            println("Benefit for ", curts[c].OPF_data.description, ":               ", curts[c].OPF_data.objective_b)
            bs[c+1] = curts[c].OPF_data.objective_b
        end
    end
    if type == "sim"
        bs = zeros(length(curts)+1)
        bs[1] = naive.objective
        println("Benefit without constraints:               ", naive.objective)
        for c in 1:length(curts)
            println("Benefit for ", curts[c].OPF_data.description, ":               ", curts[c].OPF_data.simulated_benefit)
            bs[c+1] = curts[c].OPF_data.simulated_benefit
        end
    end

    labs = String[]
    labs = push!(labs, "Naive")
    for n_curt in 1:length(curts)
        labs = push!(labs, curts[n_curt].OPF_data.description)
    end
    labs = permutedims(labs)

    bs_index_val = bs[2]

    bar(bs , xticks=(1:length(labs), labs), legend=false, xrotation =20, ylabel="Benefit over end column", title=string("Benefit comparison at time ",time))

end

function plot_expected_benefit_over_multiple_time_periods(c_list, subset)

    n_curtailments_per_t = length(c_list[1]);
    time_length = length(c_list);

    results = zeros(time_length, n_curtailments_per_t)

    if subset == "all"
        for time in 1:time_length
            for curt in 1:n_curtailments_per_t
                results[time, curt] = c_list[time][curt].OPF_data.objective_b
            end
        end
    end

    if subset == "active"
        for time in 1:time_length
            for curt in [1, 3, 5]
                results[time, curt] = c_list[time][curt].OPF_data.objective_b
            end
        end
    end

    if subset == "reactive"
        for time in 1:time_length
            for curt in [2, 4, 6]
                results[time, curt] = c_list[time][curt].OPF_data.objective_b
            end
        end
    end

    x_labels = DateTime(2021, 6, 14, 4, 5, 0):Minute(5):DateTime(2021, 6, 14, 5, 0, 0)

    plot(x_labels, results, ylims = [-Inf, maximum(results)], xrotation =20, xticks=x_labels)

end

function plot_realised_benefit_over_multiple_time_periods(n_list, subset)

    n_curtailments_per_t = length(n_list[1]);
    time_length = length(n_list);

    results = zeros(time_length, n_curtailments_per_t)

    for time in 1:time_length
        for curt in 1:n_curtailments_per_t
            results[time, curt] = n_list[time][curt].objective
        end
    end

    if subset == "all"
        plot_subset =  1:6
        legend_titles = ["Stochastic" "Stochastic reactive" "l1 norm" "l1 norm reactive" "l2 norm" "l2 norm reactive"]
    end

    if subset == "active"
        plot_subset =  [1, 3, 5]
        legend_titles = ["Stochastic" "l1 norm" "l2 norm"]
    end

    if subset == "reactive"
        plot_subset =  [2, 4, 6]
        legend_titles = ["Stochastic" "l1 norm" "l2 norm"]
    end

    x_labels = DateTime(2021, 6, 14, 4, 5, 0):Minute(5):DateTime(2021, 6, 14, 5, 0, 0)

    plot(x_labels, results[:,plot_subset], 
    ylabel="Benefit", ylims = [0, maximum(results)], 
    xlabel="Time", xrotation =20, xticks=x_labels[1:3:end], 
    labels=legend_titles, legend=:bottomleft)

end

function plot_benefits_combined_data(xlabels, benefits_combined, rows_to_plot)
    plot(xlabels, benefits_combined[:,rows_to_plot], 
    xlabel="Time", xrotation=20, xticks = x_labels[1:6:end], 
    ylabel = "Benefit", ylims = [0, maximum(expected_benefits)], 
    legend=:bottomleft)
end

function max_allowed_bid_value_nodal(list_c, time, curt)
    c = list_c[time][curt]
    caps = c.capacities
    
    # size dispatch is [a, c, i, m]

    max_e_gen_bids = zeros(69)
    for node in 1:69
        caps_gen = caps[:, :, node, 1]
        caps_gen_bin = caps_gen  .> 1e-3
        bids_bin = bids[:,:,1] .* caps_gen_bin
        max_e_gen_bids[node] = maximum(bids_bin)
    end

    return max_e_gen_bids

end

function benefit_breakdown(list_c, time, curt, prices, loss_factor, bids)

    prices_array = transpose([prices.energy prices.energy prices.raise_reg prices.lower_reg prices.raise_reg prices.lower_reg prices.raise_6_sec prices.raise_60_sec prices.raise_5_min prices.lower_6_sec prices.lower_60_sec prices.lower_5_min])
    probabilities = prices.probabilities
    benefits_in_each_market = zeros(12)
    n_scenarios = length(prices.probabilities)
    n_aggs = 3; n_bands = 10; n_nodes = 69;

    cu = list_c[time][curt]

    benefits_in_each_market[1] = sum(probabilities[s] * 
                                        (prices_array[1,s] * sum(cu.OPF_data.simulated_dispatch[a,c,i,1,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) * loss_factor
                                        - sum(bids[a,c,1] * cu.OPF_data.simulated_dispatch[a,c,i,1,s]  for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)) for s in 1:n_scenarios)

    benefits_in_each_market[2] = sum(probabilities[s] * 
                                        (- prices_array[2,s] * sum(cu.OPF_data.simulated_dispatch[a,c,i,2,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes) * loss_factor
                                        + sum(bids[a,c,2] * cu.OPF_data.simulated_dispatch[a,c,i,2,s]  for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)) for s in 1:n_scenarios)

    for m in 3:12

        benefits_in_each_market[m] = sum(probabilities[s] * 
        
                                        + sum(prices_array[m,s] * loss_factor * cu.OPF_data.simulated_dispatch[a,c,i,m,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)
                                        - sum(bids[a,c,m] * cu.OPF_data.simulated_dispatch[a,c,i,m,s] for a in 1:n_aggs, c in 1:n_bands, i in 1:n_nodes)        
                                    for s in 1:n_scenarios)

    end

    return benefits_in_each_market

end

function voltages_over_time_given_method(cs_all_, ns_all_, method, node_list)

    voltages_up = zeros(length(node_list), length(cs_all_))
    voltages_down = zeros(length(node_list), length(cs_all_))
    println("Curtailment Description: ", cs_all_[1][method-1].OPF_data.description)
    for t_index in 1:length(cs_all_)
        for i_index in 1:length(node_list)
            if method > 1
                voltages_up[i_index, t_index] = cs_all_[t_index][method-1].OPF_data.voltages[node_list[i_index], 1]
                voltages_down[i_index, t_index] = cs_all_[t_index][method-1].OPF_data.voltages[node_list[i_index], 2]
            else
                voltages_up[i_index, t_index] = ns_all_[t_index].voltage[node_list[i_index], 1]
                voltages_down[i_index, t_index] = ns_all_[t_index].voltage[node_list[i_index], 2]
            end
        end
    end

    # println(voltages_up)
    # println(voltages_down)
    plot([1:length(cs_all_)] ./ length(cs_all_) * 23.5, transpose(voltages_up), legend=false, linecolor=:red)
    plot!([1:length(cs_all_)] ./ length(cs_all_) * 23.5, transpose(voltages_down), legend=false, linecolor=:blue)

    #return [voltages_up; voltages_down]

end

function voltages_over_time_given_node(cs_all_, ns_all_, node, method_list)
    voltages_up = zeros(length(method_list), length(cs_all_))
    voltages_down = zeros(length(method_list), length(cs_all_))
    for t_index in 1:length(cs_all_)
        for method_index in 1:length(method_list)
            voltages_up[method_index, t_index] =   value.(cs_all_[t_index][method_list[method_index]].OPF_data.nodal_max_transfer[node, 1])
            voltages_down[method_index, t_index] = value.(cs_all_[t_index][method_list[method_index]].OPF_data.nodal_max_transfer[node, 2])
        end
    end
    plot(transpose(voltages_up), legend=false, color=:red)
    plot!(transpose(voltages_down), legend=false, color=:blue)
end

function voltages_energy_only(cs, ns, simparams, network, curr_lims, load_mat, pv_mat, bids, t_bounds, markets)

    t_0 = t_bounds[1]
    T   = t_bounds[2]
    Mc  = length(cs[1])

    voltage_array = zeros(T - t_0 + 1, Mc+1, 69)
    
    # no network case first
    for t_index in 1:(T - t_0 + 1)

        print(t_index, " ")

        t = t_0 + t_index - 1

        load_slice  = load_mat[:,t]
        pv_slice    = pv_mat[:,t]

        # alternatives include extreme_gen and extreme_load

        V_n, I_n, P_n = pf_for_network_eval(simparams, network, ns[t].NDD.dispatch, 
                                            load_slice, pv_slice, bids, markets,
                                            ns[t].NDD.nodal_extreme_bid_powers)
        voltage_array[t_index, 1, :] = sqrt.(value.(V_n))

        for m in 1:Mc
            if markets == "energy"
                V_c, I_c, P_c = pf_for_network_eval(simparams, network, cs[t][m].OPF_data.simulated_dispatch, 
                                                    load_slice, pv_slice, bids, markets, 
                                                    cs[t][m].OPF_data.nodal_max_transfer)
                voltage_array[t_index, m+1, :] = sqrt.(value.(V_c))
            end
            if markets == "extreme_gen"
                voltage_array[t_index, m+1, :] = sqrt.(value.(cs[t][m].OPF_data.voltages[:,1]))
            end
            if markets == "extreme_load"
                voltage_array[t_index, m+1, :] = sqrt.(value.(cs[t][m].OPF_data.voltages[:,2]))
            end
        end

    end

    return voltage_array
end

function plot_energy_voltages(v_array_energy, v_array_raise, v_array_lower)

    lwf = 1
    lw_blue = 2
    lw_red = 1
    lw_black = 2
    ls_blue = :solid
    ls_red = :solid
    ls_black = :dash

    M = 8

    end_nodes = [35, 46, 50, 52, 65, 67, 69]

    xs = Time(0,0):Minute(5):Time(23,55)
    #xs = [1:length(v_array[:,1,1])] ./ length(v_array[:,1,1]) .* 23.5
    p1 = plot(xs,v_array_energy[:,1,27], color=:red, label="No Curtailment", linewidth=lwf*lw_red, linestyle=ls_red, legend=:topleft, xticks=Time(0,0):Hour(4):Time(20,0))
    plot!(xs,v_array_energy[:,M,27], color=:blue, label="Proposed", linewidth=lwf*lw_blue, linestyle=ls_blue, ylabel="Voltage [p.u.]")
    plot!(xs,v_array_energy[:,1,end_nodes], color=:red, label=false, linewidth=lwf*lw_red, linestyle=ls_red)#, title="Energy")
    plot!(xs,v_array_energy[:,M,end_nodes], color=:blue, label=false, linewidth=lwf*lw_blue, linestyle=ls_blue)
    plot!(xs,v_array_energy[:,1,65] ./ v_array_energy[:,1,65] .* 1.05, label="Permissible Voltage Bounds",color=:black, linestyle=ls_black, linewidth=lw_black)
    plot!(xs,v_array_energy[:,1,65] ./ v_array_energy[:,1,65] .* 0.95, label=false, color=:black, linestyle=ls_black, linewidth=lw_black)
    p2 = plot(xs,v_array_raise[:,1,27], color=:red, label="No Curtailment", linewidth=lwf*lw_red, linestyle=ls_red, legend=false, xticks=Time(0,0):Hour(4):Time(20,0))
    plot!(xs,v_array_raise[:,M,27], color=:blue, label="Proposed", linewidth=lwf*lw_blue, linestyle=ls_blue, ylabel="Voltage [p.u.]")
    plot!(xs,v_array_raise[:,1,end_nodes], color=:red, label=false, linewidth=lwf*lw_red, linestyle=ls_red)#, title="Maximum Raise")
    plot!(xs,v_array_raise[:,M,end_nodes], color=:blue, label=false, linewidth=lwf*lw_blue, linestyle=ls_blue)
    plot!(xs,v_array_raise[:,1,65] ./ v_array_raise[:,1,65] .* 1.05, label="Permissible Voltage Bounds",color=:black, linestyle=ls_black, linewidth=lw_black)
    plot!(xs,v_array_raise[:,1,65] ./ v_array_raise[:,1,65] .* 0.95, label=false, color=:black, linestyle=ls_black, linewidth=lw_black)
    p3 = plot(xs,v_array_lower[:,1,27], color=:red, label="No Curtailment", linewidth=lwf*lw_red, linestyle=ls_red, legend=false, xticks=Time(0,0):Hour(4):Time(20,0))
    plot!(xs,v_array_lower[:,M,27], color=:blue, label="Proposed", linewidth=lwf*lw_blue, linestyle=ls_blue, ylabel="Voltage [p.u.]")
    plot!(xs,v_array_lower[:,1,end_nodes], color=:red, label=false, linewidth=lwf*lw_red, linestyle=ls_red)#, title="Maximum Lower")
    plot!(xs,v_array_lower[:,M,end_nodes], color=:blue, label=false, linewidth=lwf*lw_blue, linestyle=ls_blue)
    plot!(xs,v_array_lower[:,1,65] ./ v_array_lower[:,1,65] .* 1.05, label="Permissible Voltage Bounds",color=:black, linestyle=ls_black, linewidth=lw_black)
    plot!(xs,v_array_lower[:,1,65] ./ v_array_lower[:,1,65] .* 0.95, label=false, color=:black, linestyle=ls_black, linewidth=lw_black)
    p4 = plot(xs,transpose(sum(load_mat[:,1:length(xs)], dims=1)) , label="Total Fixed Load", legend=false, ylabel="Power [kW]")
    plot!(xs,-transpose(sum(pv_mat[:,1:length(xs)], dims=1) ) , label="Total PV Generation")
    plot(p1, p2, p3, layout=(3,1),  size = (600, 1.2*600))
end

function plot_network_chars(load_mat, pv_mat)
    xs = Time(0,0):Minute(5):Time(23,30)
    plot(xs,transpose(sum(load_mat[:,1:length(xs)], dims=1)) , label="Total Fixed Load", ylabel="Power [kW]", size=(600, 0.3*600))
    plot!(xs,-transpose(sum(pv_mat[:,1:length(xs)], dims=1) ) , label="Total PV Generation", xticks=Time(0,0):Hour(6):Time(18,0))
end

function plot_prices_and_predictions(t_start, T, indices)

    # True prices - create an array without times
    prices_df = CSV.read("data//price_data_csv//SA1_20210312_true_prices.csv", DataFrame);
    price_values = prices_df.RRP[indices]

    # to delete later
    
    increment = Minute(5)
    probs_of_interest = [0.8, 0.6, 0.4, 0.2]
    ribbons     = zeros(2*length(probs_of_interest), length(t_start:increment:T))

    #price_values = indices

    for t_index in 1:length(t_start:increment:T)
        t = t_start + Minute(5) * (t_index - 1)
        pdf_array = generate_price_pdf(t,state)
        pdf_array = [pdf_array  cumsum(prob_mat[:,2])]
        # display(pdf_array)
        for p in 1:length(probs_of_interest)
            p_high = 0.5 + probs_of_interest[p]/2
            ind_above = findfirst(pdf_array[:,3] .> p_high)
            # println(ind_above)
            p_gap_above = pdf_array[ind_above,3] - p_high
            p_gap_below = p_high - pdf_array[ind_above-1,3]
            # println(p_gap_above, " ", p_gap_below)
            price = (pdf_array[ind_above, 1] * p_gap_below + pdf_array[ind_above-1, 1] * p_gap_above) ./ (p_gap_above + p_gap_below)
            ribbons[2*p, t_index] = price

            p_low = 0.5 - probs_of_interest[p]/2
            ind_above = findfirst(pdf_array[:,3] .> p_low)
            # println(ind_above)
            p_gap_above = pdf_array[ind_above,3] - p_low
            p_gap_below = p_low - pdf_array[ind_above-1,3]
            price = (pdf_array[ind_above, 1] * p_gap_below + pdf_array[ind_above-1, 1] * p_gap_above) ./ (p_gap_above + p_gap_below)
            ribbons[2*p - 1, t_index] = price
        end
    end

    # display(ribbons)

    ribbons = ribbons .- transpose(price_values)
    ribbons[2 * (1:length(probs_of_interest)) .- 1, :] = - ribbons[2 * (1:length(probs_of_interest)) .- 1, :]

    # display(ribbons)

    # plt = plot()
    # for case in 1:length(probs_of_interest)
    #     plot!(price_values, ribbon = (ribbons[2*case-1,:], ribbons[2*case,:]), color=:red)
    # end

    return price_values, ribbons, Time(t_start):Minute(5):Time(T)
end

function make_prediction_plot()
    t_start     = DateTime(2021, 3, 12, 0, 0, 0)
    T           = DateTime(2021, 3, 12, 23, 55, 0)
    indices     = 1:288
    price_values, ribbons, tms = plot_prices_and_predictions(t_start, T, indices);
    p1 = plot(tms, price_values, ribbon=(ribbons[1,:], ribbons[2,:]), linewidth = 0; color=:yellow, label="80% confidence interval", xticks=Time(0,0):Hour(4):Time(20,0))
    plot!(tms, price_values, ribbon=(ribbons[3,:], ribbons[4,:]), linewidth = 0; color=:orange, label="60% confidence interval")
    plot!(tms, price_values, ribbon=(ribbons[5,:], ribbons[6,:]), linewidth = 0; color=:red, label="40% confidence interval")
    plot!(tms, price_values, ribbon=(ribbons[7,:], ribbons[8,:]), linewidth = 0; color=:red4, label="20% confidence interval")
    plot!(tms, price_values, linewidth = 1; color=:black, label="True Prices", legend=:topleft, ylabel="Energy Price [\$]")
    t_start     = DateTime(2021, 3, 12, 17, 00, 0)
    indices     = 205:288
    price_values, ribbons, tms = plot_prices_and_predictions(t_start, T, indices);
    p2 = plot(tms, price_values, ribbon=(ribbons[1,:], ribbons[2,:]), linewidth = 0; color=:yellow, label="80% confidence", xticks=Time(17,00):Hour(1):Time(23,0))
    plot!(tms, price_values, ribbon=(ribbons[3,:], ribbons[4,:]), linewidth = 0; color=:orange, label="60% confidence")
    plot!(tms, price_values, ribbon=(ribbons[5,:], ribbons[6,:]), linewidth = 0; color=:red, label="40% confidence")
    plot!(tms, price_values, ribbon=(ribbons[7,:], ribbons[8,:]), linewidth = 0; color=:red4, label="20% confidence")
    plot!(tms, price_values, linewidth = 1; color=:black, label="True Prices", legend=false, ylabel="Energy Price [\$]")
    plot(p1, p2, layout=(2,1))
end

function save_serialised_data(var, filename)
    open(string("saved_data\\",filename,".bin"), "w") do f
        serialize(f, var)
    end
end
