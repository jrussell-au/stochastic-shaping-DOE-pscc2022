using Dates, CSV, Tables, DataFrames, TimeZones

function build_load_dictionary()

    dir_root = "data/load/Paul_csvs/"
    readdir_result = readdir(dir_root)

    date_format = "yyyy-mm-ddTHH:MM:SSzzzz"

    n_custs = length(readdir_result) - 1

    load_dict = Dict()

    for i in 1:n_custs
        #print(i)
        load_info = CSV.read(
            string(dir_root, readdir_result[i]),
            DataFrame
            )
        load_info.time = Time.(load_info.time, date_format)
        load_dict[i] = load_info
        #println(" -done")
    end

    return load_dict

end

compo_label = "unitary"
include(string("../../data/network_composition_dictionaries/",compo_label,"_composition_dictionary.jl"))


n_aggs = 3
n_nodes = 69

ld = build_load_dictionary()

# first start with load
# goal is to create a CSV file for load, of dimensions 69 by 288 (n by T) with load data

load_data = zeros(69,288)
pv_data = zeros(69,288)

for t in 1:288

    sim_datetime = DateTime(2021, 1, 1) + Dates.Minute((t-1)*5)

    recorded_loads_at_that_time = []
    recorded_pv_at_that_time = []

    for data_cust in 1:length(ld)
        new_loads = ld[data_cust][ld[data_cust].time .== Time(sim_datetime),:].p_ld
        new_pv =    ld[data_cust][ld[data_cust].time .== Time(sim_datetime),:].p_pv
        for entry in 1:length(new_loads)
            push!(recorded_loads_at_that_time, new_loads[entry])
        end
        for entry in 1:length(new_pv)
            push!(recorded_pv_at_that_time, new_pv[entry])
        end
    end

    # Generates a set of loads, equal to the number of individual customers in network with a load value
    loads = repeat(recorded_loads_at_that_time, outer = Int64(ceil(1268 / length(recorded_loads_at_that_time))));
    loads = loads[1:1268];
    pvs = repeat(recorded_pv_at_that_time, outer = Int64(ceil(507 / length(recorded_pv_at_that_time))));
    pvs = pvs[1:507];

    # Creates (and puts away) a 69-vector with sum of load values at each node equal to the value in load_composition dictionary
    customer_iterator = [1]
    prosumer_iterator = [1]
    for i in 1:n_nodes
        ci = Int64(customer_iterator[1])
        pi = Int64(prosumer_iterator[1])
        println("node: ", i)
        println("ci and pi: ", ci, ", ",pi)
        if load_composition[i] > 0
            load_data[i,t]  = sum(loads[Int64(k)] for k in ci:(ci + load_composition[i]-1))
        end
        if pv_composition[i] > 0
            pv_data[i,t]    = sum(  pvs[Int64(k)] for k in pi:(pi + pv_composition[i]-1))
        end
        customer_iterator[1] = customer_iterator[1] + load_composition[i]
        prosumer_iterator[1] = prosumer_iterator[1] + pv_composition[i]
    end

    println(customer_iterator[1])
    println(prosumer_iterator[1])

end

CSV.write(string("data/load/",compo_label, "_loads.csv"),  Tables.table(load_data), writeheader=false)
CSV.write(string("data/pv_data_csv/",compo_label, "_pv.csv"),  Tables.table(pv_data), writeheader=false)





























# datatype = "load"

# compo_label = "real_load_data"
# loads_per_agg_node = zeros(n_nodes, 288);

# include(string("../../data/network_composition_dictionaries/",compo_label,"_composition_dictionary_TEST.jl"))
# #composition[node][agg]["battery"] # name of compo dictionary 
# n_nodes = 69

# customer_agg_node_matrix = zeros(n_aggs, n_nodes);
# for a in 1:n_aggs, i in 1:n_nodes
#     customer_agg_node_matrix[a,i] = prosumer_composition[i][a]["prosumers"]
# end
# N_customers = Int64(sum(customer_agg_node_matrix))

# # ld is dictionary - each fake customer / 30 has a dataframe, where x axis is times (multiple days) and y axis is info type.

# for t in 1:288

# end

# # end goal is to produce a CSV for load, of dimensions 69 by 288 (n by T) with load data






# for t in 1:288
#     sim_datetime = DateTime(2021, 1, 1, 0, 0, 0) + Dates.Minute(t*5)

#     loads = []
#     for customer in 1:length(ld)
#         if datatype == "pv"
#             new_loads = ld[customer][ld[customer].time .== Time(sim_datetime),:].p_pv
#         end
#         if datatype == "load"
#             new_loads = ld[customer][ld[customer].time .== Time(sim_datetime),:].p_ld
#         end
#         for entry in 1:length(new_loads)
#             push!(loads, new_loads[entry])
#         end
#     end
#     loads = repeat(loads, outer = Int64(ceil(N_customers / length(loads))));
#     loads = loads[1:N_customers];

#     global customer_iterator = [1]

#     for a in 1:n_aggs, i in 1:n_nodes
#         ci = Int64(customer_iterator[1])
#         if customer_agg_node_matrix[a,i] > 0
#             loads_per_agg_node[a, i, t] = sum(loads[Int64(k)] for k in ci:(ci+customer_agg_node_matrix[a,i]-1))
#             customer_iterator[1] = customer_iterator[1] + customer_agg_node_matrix[a,i]
#         end
#     end
# end

# loads_per_agg_node = reshape(loads_per_agg_node, (207, 288))
# if datatype == "pv"
#     CSV.write(string("data/pv_data_csv/",compo_label, "_pv.csv"),  Tables.table(loads_per_agg_node), writeheader=false)
# end
# if datatype == "load"
#     CSV.write(string("data/load/",compo_label, "_loads.csv"),  Tables.table(loads_per_agg_node), writeheader=false)
# end


