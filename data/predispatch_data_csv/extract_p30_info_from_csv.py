import os
import glob
import pandas as pd
import datetime as dt
import numpy as np
import csv

date_of_interest = dt.datetime(2021, 3, 12)

for state in ["NSW1", "QLD1", "SA1", "TAS1", "VIC1"]:

    print(state)

    start_time  = date_of_interest
    end_time    = start_time + dt.timedelta(hours=23, minutes=30)
    time = start_time
    df_concat = pd.DataFrame()

    while time <= end_time:

        foldername          = "data/predispatch_data_csv/predispatch data/"
        file_root_name      = "PUBLIC_PREDISPATCHIS_"

        date_component = time.strftime('%Y%m%d%H%M')

        dir_ = glob.glob(foldername + "/" + file_root_name + date_component + "_**************")

        first_line = 0
        with open(dir_[0], newline='') as f:
            reader = csv.reader(f)
            for row in reader:
                if(row[9]) == "RRP":
                    break
                first_line += 1

        df = pd.read_csv(dir_[0], skiprows=first_line, nrows=10, parse_dates=['DATETIME'])#,
        df = df.loc[df["DATETIME"] == time]
        df = df.loc[df["REGIONID"] == state]

        list_of_headers = ["DATETIME","RRP", "RAISEREGRRP", "LOWERREGRRP", "RAISE6SECRRP", "RAISE60SECRRP", "RAISE5MINRRP", "LOWER6SECRRP", "LOWER60SECRRP", "LOWER5MINRRP"]

        df = df[list_of_headers]
        df_concat = pd.concat([df_concat, df])
        time = time + dt.timedelta(minutes=30)

    df_concat.to_csv("data/predispatch_data_csv/" + str(state) + "_" + start_time.strftime('%Y%m%d') + "_p30.csv")