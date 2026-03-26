

#file = "U3NXVDWX-out.csv"

dir_name = joinpath(@__DIR__, "Paul_csvs")
d = readdir(dir_name)

pv_full_data = zeros(length(d)*5, 288)

for n in 1:length(d)
    
    file = d[n]

    println(file)

    data = CSV.read(string(dir_name, "\\",file), DataFrame);
    # plot!(plt, - data.p_ld*ld_switch)

    pv_full_data[(n-1)*5 + 1, :] = data.p_pv[1:288]
    pv_full_data[(n-1)*5 + 2, :] = data.p_pv[289:576]
    pv_full_data[(n-1)*5 + 3, :] = data.p_pv[577:864] 
    pv_full_data[(n-1)*5 + 4, :] = data.p_pv[865:1152] 
    pv_full_data[(n-1)*5 + 5, :] = data.p_pv[1153:1440]

    # push!(inv_list, minimum(data.p_inv))
    # push!(ld_list, maximum(data.p_ld))
    # push!(pv_list, minimum(data.p_pv))

end

load_full_data = zeros(length(d)*5, 288)

for n in 1:length(d)
    
    file = d[n]

    println(file)

    data = CSV.read(string(dir_name, "\\",file), DataFrame);
    # plot!(plt, - data.p_ld*ld_switch)

    load_full_data[(n-1)*5 + 1, :] = data.p_ld[1:288]
    load_full_data[(n-1)*5 + 2, :] = data.p_ld[289:576]
    load_full_data[(n-1)*5 + 3, :] = data.p_ld[577:864] 
    load_full_data[(n-1)*5 + 4, :] = data.p_ld[865:1152] 
    load_full_data[(n-1)*5 + 5, :] = data.p_ld[1153:1440]

    # push!(inv_list, minimum(data.p_inv))
    # push!(ld_list, maximum(data.p_ld))
    # push!(pv_list, minimum(data.p_pv))

end

# 0.6, where 0.7458 is the limit
lims = [0.0, 0.0, 0.0, 0.0, 0.0, 1.56, 24.24, 45.0, 18.0, 16.8, 87.0, 87.0, 4.8, 4.8, 0.0, 27.3, 36.0, 36.0, 0.0, 0.6, 68.4, 3.0, 0.0, 16.8, 0.0, 8.4, 8.4, 15.6, 15.6, 0.0, 0.0, 0.0, 8.4, 11.7, 3.6, 15.6, 15.6, 0.0, 14.4, 14.4, 0.72, 0.0, 3.6, 0.0, 23.532, 23.532, 0.0, 47.4, 230.82, 230.82, 24.3, 2.16, 2.61, 15.84, 14.4, 0.0, 0.0, 0.0, 60.0, 0.0, 746.4, 19.2, 0.0, 136.2, 35.4, 10.8, 10.8, 16.8, 16.8]


# cust_alloc  = Model(Gurobi.Optimizer)
# set_optimizer_attribute(cust_alloc, "TimeLimit", 220)

# # fixed vars = 

# @variable(cust_alloc, 0 <= unit_commits_to_nodes[c in 1:150, i in 1:69], Int)
# @variable(cust_alloc, 0 <= number_of_sets, Int)

# @objective(cust_alloc, Max, sum(unit_commits_to_nodes))

# @constraint(cust_alloc, maxes_across_time[i in 1:69, t in 1:288],
#     sum(unit_commits_to_nodes[c, i] * loads[c, t]  for c in 1:150) <= lims[i]
# )
# @constraint(cust_alloc, equal_distribution[c in 1:150],
#     sum(unit_commits_to_nodes[c, i] for i in 1:69) <= number_of_sets
# )
# @constraint(cust_alloc, equal_distribution_above[c in 1:150],
#     sum(unit_commits_to_nodes[c, i] for i in 1:69) >= number_of_sets - 1
# )
# status = JuMP.optimize!(cust_alloc);

# print(value.(unit_commits_to_nodes))

# filename = d[end-1]
# data = CSV.read(string(dir_name, "\\",filename), DataFrame);
# plot!(data.p_ld)

# plot(-inv_list)
# plot!(ld_list)

# res = [-5*ones(size(inv_list)) ld_list pv_list 5*ones(size(inv_list)) ./ ld_list]

# display(res)

#histogram(- inv_list ./ ld_list)
# CP = INV + LD + PV 

















# pv_df                   = CSV.read("pv_full_data.csv", DataFrame, header=false)
# pv_df_to_mat            = Matrix(load_df)
allocation_df           = CSV.read(joinpath(@__DIR__, "..", "allocations.csv"), DataFrame, header=false)
allocation_df_to_mat    = Matrix(allocation_df)

load_per_node = zeros(69, 288)
for i in 1:69, t in 1:288
    load_per_node[i, t] = sum(    allocation_df_to_mat[cst, i]  *   load_full_data[cst, t]       for cst in 1:150)
end


pv_per_node = zeros(69, 288)
for i in 1:69, t in 1:288
    pv_per_node[i, t] = sum(    allocation_df_to_mat[cst, i]  *   pv_full_data[cst, t]       for cst in 1:150)
end





load_per_node_df = DataFrame(load_per_node, :auto)
pv_per_node_df = DataFrame(pv_per_node, :auto)

CSV.write(joinpath(@__DIR__, "..", "load_per_node.csv"), load_per_node_df, writeheader=false)
CSV.write(joinpath(@__DIR__, "..", "pv_per_node.csv"), pv_per_node_df, writeheader=false)