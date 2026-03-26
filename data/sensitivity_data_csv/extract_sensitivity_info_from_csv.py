import os
import glob
import pandas as pd
import datetime as dt
import numpy as np
import csv

date_of_interest = dt.datetime(2021, 3, 12)

end_time    = date_of_interest + dt.timedelta(days=1) - dt.timedelta(minutes=5)

# states of interest

# create array where axis 1 is predispatch sensitivity value,   axis 2 is state,    axis 3 is time (generally will only be 1)
# create array where axis 1 is p10, p50 and p90 values,         axis 2 is state,    axis 3 is time

# identify files of interest for predispatch sensitivity value

time = date_of_interest - dt.timedelta(minutes=30)
df_concat = pd.DataFrame()
while time < end_time:
    print(time)

    foldername          = "data/sensitivity_data_csv/sensitivity data"
    file_root_name      = "PUBLIC_PREDISPATCH_SENSITIVITIES_"

    date_component = time.strftime('%Y%m%d%H%M')[0:-1]
    dir_ = glob.glob(foldername + "/" + file_root_name + date_component + "***_****************")

    first_line = 0
    with open(dir_[0], newline='') as f:
        reader = csv.reader(f)
        for row in reader:

            if(row[1]) == "PREDISPATCH":
                break
            first_line += 1

    df = pd.read_csv(dir_[0],
            header = first_line,
            nrows = 5)

    list_of_headers = ["REGIONID", "DATETIME"]

    for pd_index in range(1, 21):
        list_of_headers.append("RRPEEP" + str(pd_index))

    for pd_index in range(25, 44):
        list_of_headers.append("RRPEEP" + str(pd_index))

    #print(list_of_headers)
    df = df[list_of_headers]
    df_concat = pd.concat([df_concat, df])

    time = time + dt.timedelta(minutes=30)
df_concat.to_csv("data/sensitivity_data_csv/AUS_" + date_of_interest.strftime('%Y%m%d') + "_psens.csv")