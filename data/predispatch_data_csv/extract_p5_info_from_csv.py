import os
import glob
import pandas as pd
import datetime as dt
import numpy as np
import csv

# FUTURE DIRECTIONS - USE DATETIME OBJECTS TO SOURCE FROM MORE FLEXIBLE RANGES FOR DATA

minutes_forward = 5
forward_outlook = dt.timedelta(minutes=minutes_forward - 5)

date_of_interest = dt.datetime(2021, 3, 12)


for region in ['NSW1', 'SA1', 'VIC1', 'QLD1', 'TAS1']:

    print(region)

    start_time =    date_of_interest - forward_outlook
    end_time =      date_of_interest + dt.timedelta(days=1) - dt.timedelta(minutes=5) - forward_outlook

    time = start_time

    df_concat = pd.DataFrame()

    while time <= end_time:

        #print(glob.glob("data/predispatch_data_csv/predispatch_data/PUBLIC_P5MIN_" + time.strftime("%Y%m%d%H%M") + "_**************.csv"))
        file = glob.glob("data/predispatch_data_csv/p5 data/PUBLIC_P5MIN_" + time.strftime("%Y%m%d%H%M") + "_**************.csv")[0]

        #print(dir_ + "/" + file + '.csv')

        ###### determine how many lines to skip
        first_line = 0
        with open(file, newline='') as f:
            reader = csv.reader(f)
            for row in reader:

                if(row[2]) == "REGIONSOLUTION":
                    break
                first_line += 1

        #print(first_line)
        df = pd.read_csv(file,
                        header = first_line,
                        nrows = 60)



        df['INTERVAL_DATETIME'] = pd.to_datetime(df['INTERVAL_DATETIME'])
        df = df.loc[df['REGIONID'] == region]
        #print(df)
        df = df.loc[df['INTERVAL_DATETIME'] == time + forward_outlook]             #min(df['INTERVAL_DATETIME'])]

        # df = df.loc[df['SETTLEMENTDATE'] >= dt.datetime(2021, 6, 14, 4, 5)]
        # df = df.loc[df['SETTLEMENTDATE'] <= dt.datetime(2021, 6, 15, 4, 0)]

        list_of_headers = [
        'INTERVAL_DATETIME',
        'RRP',
        'RAISEREGRRP',
        'LOWERREGRRP',
        'RAISE6SECRRP',
        'RAISE60SECRRP',
        'RAISE5MINRRP',
        'LOWER6SECRRP',
        'LOWER60SECRRP',
        'LOWER5MINRRP',
        ]

        df = df[list_of_headers]
        df_concat = pd.concat([df_concat, df])

        #print(df_concat)

        time += dt.timedelta(minutes=5)

    df_concat.to_csv("data/predispatch_data_csv/" + region + "_" + end_time.strftime("%Y%m%d") + "_p" + str(minutes_forward) + ".csv")


#print(type(dir_))
#print(dir_)

# --------------------------------

# import pandas as pd
# import datetime as dt

# region = "SA1"

# time_start = 202106140000
# filename = str("data/PUBLIC_PRICES_" + str(202106140000) + "_20210615040501.CSV")

# df = pd.read_csv("data/PUBLIC_PRICES_202106140000_20210615040501.CSV")
# df['SETTLEMENTDATE'] = pd.to_datetime(df['SETTLEMENTDATE'])


# df = df.loc[df['REGIONID'] == region]

# df = df.loc[df['SETTLEMENTDATE'] >= dt.datetime(2021, 6, 14, 4, 5)]
# df = df.loc[df['SETTLEMENTDATE'] <= dt.datetime(2021, 6, 15, 4, 0)]
 
# list_of_headers = [
# 'SETTLEMENTDATE',
# 'RRP',
# 'RAISEREGRRP',
# 'LOWERREGRRP',
# 'RAISE6SECRRP',
# 'RAISE60SECRRP',
# 'RAISE5MINRRP',
# 'LOWER6SECRRP',
# 'LOWER60SECRRP',
# 'LOWER5MINRRP',
# ]

# df = df[list_of_headers]

# df.to_csv(str("data/" + region + "_" + str(time_start) + ".csv"))