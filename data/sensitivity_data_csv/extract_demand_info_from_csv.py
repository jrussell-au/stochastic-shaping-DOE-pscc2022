import os
import glob
import pandas as pd
import datetime as dt
import numpy as np
import csv

date_of_interest = dt.datetime(2021, 3, 12)

start_time  = date_of_interest
end_time    = date_of_interest + dt.timedelta(hours=23, minutes=55)

shuffle_back_flag = 0

time = start_time
df_concat = pd.DataFrame()
while time <= end_time:

    #print(" ")
    print(time)

    foldername          = "data/sensitivity_data_csv/demand data"
    file_root_name      = "PUBLIC_FORECAST_OPERATIONAL_DEMAND_HH_"

    date_component = time.strftime('%Y%m%d%H%M')

    dir_ = glob.glob(foldername + "/" + file_root_name + date_component + "_****************")

    #print(dir_)
    #print(dir_[0])

    test_state = "NSW1"
    first_line = 0
    with open(dir_[0], newline='') as f:
        reader = csv.reader(f)
        for row in reader:
            if(row[4]) == test_state:
                break
            first_line += 1
    df = pd.read_csv(dir_[0],
            header = 1,
            nrows = first_line-1,
            parse_dates=['INTERVAL_DATETIME'])
    df = df.iloc[[-1]]

    #print(df['INTERVAL_DATETIME'].values[-1])
    #print(np.datetime64(time))

    if df['INTERVAL_DATETIME'].values[-1] > np.datetime64(time):
        shuffle_back_flag = 1
        #print("shuffle_back_flag_raised")
        time = time - dt.timedelta(minutes=30)
        date_component = time.strftime('%Y%m%d%H%M')
        dir_ = glob.glob(foldername + "/" + file_root_name + date_component + "_****************")


    for state in ["NSW1", "QLD1", "SA1", "TAS1", "VIC1"]:

        first_line = 0
        with open(dir_[0], newline='') as f:
            reader = csv.reader(f)
            for row in reader:

                if shuffle_back_flag == 0:
                    if(row[4]) == state:
                        time_of_interest = time - (shuffle_back_flag* dt.timedelta(minutes=30))
                        if(row[5]) == time.strftime("%Y/%m/%d %H:%M:%S"):
                            break
                    first_line += 1
                else:
                    if(row[4]) == state:
                        time_of_interest = time + (shuffle_back_flag* dt.timedelta(minutes=30))
                        time_of_interest.strftime("%Y/%m/%d %H:%M:%S")
                        if(row[5]) == time_of_interest.strftime("%Y/%m/%d %H:%M:%S"):
                            break
                    first_line += 1

        df = pd.read_csv(dir_[0],
                header = 1,
                nrows = first_line-1,
                parse_dates=['INTERVAL_DATETIME'])

        df = df.iloc[[-1]]

        list_of_headers = ["REGIONID", "INTERVAL_DATETIME", "OPERATIONAL_DEMAND_POE10", "OPERATIONAL_DEMAND_POE50", "OPERATIONAL_DEMAND_POE90"]

        df = df[list_of_headers]
        df_concat = pd.concat([df_concat, df])



    if shuffle_back_flag == 1:
        time = time + dt.timedelta(minutes=30)
        shuffle_back_flag = 0

    time = time + dt.timedelta(minutes=30)

#print(df_concat)
df_concat.to_csv("data/sensitivity_data_csv/AUS_" + start_time.strftime('%Y%m%d') + "_demand.csv")