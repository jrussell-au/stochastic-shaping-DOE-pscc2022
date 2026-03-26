using JSON

function get_data(compo_label, sim_datetime)

    JSON_filename = joinpath("data", string("batt-bids-", string(Date(sim_datetime - Minute(60*4+5))), ".json"))
    data = JSON.parsefile(JSON_filename);
    time_stamp_counter = [0]
    found_time = [0]
    while found_time[1] == 0
        time_stamp_counter[1] = time_stamp_counter[1] + 1
#        print(time_stamp_counter[1])
        string_to_check = data["HPRG1"]["ENERGY"]["capacities"]["INTERVAL_DATETIME"][time_stamp_counter[1]]
        if string_to_check == string(sim_datetime)
            found_time[1] = 1
        end
    end
    time_stamp = time_stamp_counter[1]
#
    include(string("data/network_composition_dictionaries/",compo_label,"_composition_dictionary.jl"));
    #println("At each node, 5 customers belong to agg1, 6 belong to agg2, and 30 belong to agg3")

    # Index names and locations
    location_keys = ["LBB", "BALB", "HPR"]
    suffixes = ["G1", "L1"]
    markets_G =     ["ENERGY", "RAISEREG", "LOWERREG", "RAISE6SEC", "RAISE60SEC", "RAISE5MIN"]
    index_map_G =   [1, 3, 4, 7, 8, 9]
    markets_L =     ["ENERGY", "RAISEREG", "LOWERREG", "LOWER6SEC", "LOWER60SEC", "LOWER5MIN"]
    index_map_L =   [2, 5, 6, 10, 11, 12]

    state_keys = ["SA", "SA", "SA"]

    #CSV.read("C:\\Users\\u5542624\\Desktop\\Code\\Stochastic Git\\SA_prices.csv")

    # Value placeholders
    bids =          zeros(length(location_keys), 10, 12)
    capacities =    zeros(length(location_keys), 10, 69, 12)
    trapeziums =    zeros(3,5,69,10);

    # Sim variables
    capacity_factor = 69
    population = 69

    # Populate data using JSON
    for l_index in 1:length(location_keys)
        l = location_keys[l_index]
        key = string(l, suffixes[1])
        for market_number in 1:6
            market = index_map_G[market_number]
            for band in 1:10
                #println(key, " ", markets_G[market_number], " ",band)
                bids[l_index, band, market] =                       data[key][markets_G[market_number]]["prices"][string("PRICEBAND",band)][1]
                for node in 1:69
                    capacities[l_index, band, node, market] =       data[key][markets_G[market_number]]["capacities"][string("BANDAVAIL",band)][time_stamp]
                end
            end
            # If not energy market
            if market > 2
                for node in 1:69
                    trapeziums[l_index,1,node,market-2] =             data[key][markets_G[market_number]]["trapeziums"]["MAXAVAIL"][time_stamp]
                    trapeziums[l_index,2,node,market-2] =             data[key][markets_G[market_number]]["trapeziums"]["ENABLEMENTMIN"][time_stamp]
                    trapeziums[l_index,3,node,market-2] =             data[key][markets_G[market_number]]["trapeziums"]["ENABLEMENTMAX"][time_stamp]
                    trapeziums[l_index,4,node,market-2] =             data[key][markets_G[market_number]]["trapeziums"]["LOWBREAKPOINT"][time_stamp]
                    trapeziums[l_index,5,node,market-2] =             data[key][markets_G[market_number]]["trapeziums"]["HIGHBREAKPOINT"][time_stamp]
                end
            end
        end
        key = string(l, suffixes[2])
        for market_number in 1:6
            market = index_map_L[market_number]
            for band in 1:10
                #println(key, " ", markets_L[market_number], " ",band)
                bids[l_index, band, market] =                       data[key][markets_L[market_number]]["prices"][string("PRICEBAND",band)][1]
                for node in 1:69
                    capacities[l_index, band, node, market] =       data[key][markets_L[market_number]]["capacities"][string("BANDAVAIL",band)][1]
                end
            end
            if market > 2
                for node in 1:69
                    trapeziums[l_index,1,node,market-2] =             data[key][markets_L[market_number]]["trapeziums"]["MAXAVAIL"][time_stamp]
                    trapeziums[l_index,2,node,market-2] =             data[key][markets_L[market_number]]["trapeziums"]["ENABLEMENTMIN"][time_stamp]
                    trapeziums[l_index,3,node,market-2] =             data[key][markets_L[market_number]]["trapeziums"]["ENABLEMENTMAX"][time_stamp]
                    trapeziums[l_index,4,node,market-2] =             data[key][markets_L[market_number]]["trapeziums"]["LOWBREAKPOINT"][time_stamp]
                    trapeziums[l_index,5,node,market-2] =             data[key][markets_L[market_number]]["trapeziums"]["HIGHBREAKPOINT"][time_stamp]
                end
            end
        end
    end

    # for     capacity_factor = 69/1000, population = 69        the reg traps return to 25, 30, 80
    capacities = capacities .* capacity_factor ./ population
    trapeziums = trapeziums .* capacity_factor ./ population

    factors = [5, 6, 30]        # these factors are what is required to divide original nominal values through to get to 5
    for agg in 1:3
        for node in 1:69
            capacities[agg,:,node,:] = capacities[agg,:,node,:] / factors[agg] * prosumer_composition[node][agg]["prosumers"]
            trapeziums[agg,:,node,:] = trapeziums[agg,:,node,:] / factors[agg] * prosumer_composition[node][agg]["prosumers"]
        end
    end

    

    return bids, capacities, trapeziums

end

#bids, capacities, trapeziums, state_keys, composition = get_data(1)