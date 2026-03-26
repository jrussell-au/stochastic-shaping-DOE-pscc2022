using JSON

function get_data(time_stamp)

data = JSON.parsefile(joinpath(@__DIR__, "batt-bids-2021-06-14.json"));

    # Index names and locations
    location_keys = ["LBB", "BALB", "HPR"]
    suffixes = ["G1", "L1"]
    markets_G =     ["ENERGY", "RAISEREG", "LOWERREG", "RAISE6SEC", "RAISE60SEC", "RAISE5MIN"]
    index_map_G =   [1, 3, 4, 7, 8, 9]
    markets_L =     ["ENERGY", "RAISEREG", "LOWERREG", "LOWER6SEC", "LOWER60SEC", "LOWER5MIN"]
    index_map_L =   [2, 5, 6, 10, 11, 12]

    # Value placeholders
    bids =          zeros(length(location_keys), 10, 12)
    capacities =    zeros(length(location_keys), 10, 69, 12)
    trapeziums =    zeros(3,5,69,10);

    # Sim variables
    capacity_factor = 1
    population = 1

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
                    capacities[l_index, band, node, market] =       data[key][markets_G[market_number]]["capacities"][string("BANDAVAIL",band)][time_stamp] / population * capacity_factor
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
                    capacities[l_index, band, node, market] =       data[key][markets_L[market_number]]["capacities"][string("BANDAVAIL",band)][1] / population * capacity_factor
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

    return bids, capacities, trapeziums

end

#bids, capacities, trapeziums = get_data(2)