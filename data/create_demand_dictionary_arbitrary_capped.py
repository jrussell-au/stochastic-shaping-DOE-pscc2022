import datetime as dt
import numpy as np
from random import shuffle
import pandas as pd

csts_total = 2000

_5_6_30 = 0
_1_1_1 = 0
_rand_1 = 0
_rand_2 = 0         # per node reduced by about 25%

real_load_data = 1

if real_load_data:
    total_count_per_agg = np.array([50000, 50000, 50000])
#    total_count_per_agg = np.array([169, 169, 169])
    agg_ids = []
    for agg in range(3):
        for rep in range(int(total_count_per_agg[agg])):
            agg_ids.append(agg+1)
    shuffle(agg_ids)

    #numbers_per_node = np.ones(69) * 30
    df = pd.read_csv("data/network_composition_dictionaries/nodal_breakdown_unitary.csv")
    customers_per_node = np.zeros(69)
    for c in range(csts_total):
        customers_per_node[int(np.random.rand() * 69)] += 1
    #customers_per_node = np.array(df["customers"]) * csts_per_node
   # customers_per_node = np.ones(np.shape(customers_per_node))

    location_ids = []
    for node in range(69):
        for rep in range(int(customers_per_node[node])):
            location_ids.append(node+1)
    #shuffle(location_ids)

    prosumer_flag = np.ones(csts_total)
    # prosumer_flag = np.tile([1, 1, 0, 0, 0], 253)
    # prosumer_flag = list(prosumer_flag)
    # prosumer_flag.append(1)
    # prosumer_flag.append(0)
    # prosumer_flag.append(0)
    #shuffle(prosumer_flag)

    #print(np.shape(location_ids))
    #print(np.shape(prosumer_flag))
    stacked = np.vstack([location_ids, prosumer_flag])
    print("location ids")
    print(location_ids)
    print("prosumer flag")
    print(prosumer_flag)
    print("agg ids")
    print(agg_ids)

    # np.transpose(np.random.shuffle(np.transpose(stacked)))
    # print(stacked)

    prosumer_iterator = 0
    customer_iterator = 0

    customers = dict()
    for node in range(1, 70):
        customers[node] = 0

    pvs = dict()
    for node in range(1, 70):
        pvs[node] = 0

    prosumers = dict()
    for node in range(1, 70):
        prosumers[node] = dict()
        prosumers[node][1] = 0
        prosumers[node][2] = 0
        prosumers[node][3] = 0

    for customer in range(len(location_ids)):
        #print("customer number " + str(asset))
        customers[location_ids[customer]] += 1
        customer_iterator += 1
        if prosumer_flag[customer] == 1:
            pvs[location_ids[customer]] += 1
            agg = agg_ids[prosumer_iterator]
            prosumers[location_ids[customer]][agg] += 1
            prosumer_iterator += 1

    print(prosumer_iterator)
    print(customer_iterator)
    print(prosumers[61])
    print(customers[61])
    print(pvs[61])

# Run in root folder
# Create a demand dictionary
def create_demand_dictionary(scenario_name, distribution):

    now = dt.datetime.now()
    filename = str(now.strftime("%Y-%m-%d-%H-%M-%S"))
    file = open(str("data/network_composition_dictionaries/" + scenario_name + "_composition_dictionary.jl"), "w")
    file.write("prosumer_composition=Dict(\n")
    for node in range(1, 70):
        file.write(str(node) + " => Dict(\n")
        for agg in range(1,4):
            file.write(str(agg) + "=>Dict(\"prosumers\" => " + str(prosumers[node][agg]) + ")")
            if agg == 3:
                0
            else:
                file.write(",\n")
        if node == 69:
            file.write(")\n)")
        else:
            file.write("),\n")

    file.write("\n\npv_composition=Dict(\n")
    for node in range(1, 70):
        file.write(str(node) + " => " + str(pvs[node]))#Dict(\n")
        if node == 69:
            file.write("\n)")
        else:
            file.write(",\n")

    file.write("\n\nload_composition=Dict(\n")
    for node in range(1, 70):
        file.write(str(node) + " => " + str(customers[node]))#Dict(\n")
        if node == 69:
            file.write("\n)")
        else:
            file.write(",\n")

    file.close()

    return 0

create_demand_dictionary("unitary",0)