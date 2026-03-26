import pandas as pd
import datetime as dt
import glob
import csv

date_of_interest = dt.datetime(2021, 3, 12)
one_day_before = date_of_interest - dt.timedelta(days=1)

# 

region = "SA1"
foldername = "data/price_data_csv/NEM Data"
file_root_name = "PUBLIC_PRICES_"

dir_prior = glob.glob(foldername + "/" + file_root_name + one_day_before.strftime('%Y%m%d%H%M') + "_**************")
dir_post  = glob.glob(foldername + "/" + file_root_name + date_of_interest.strftime('%Y%m%d%H%M') + "_**************")

print(dir_prior)
print(dir_post)


# col 8 is RRP
first_line = 0
with open(dir_prior[0], newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        if(row[8]) == "RRP":
            break
        first_line += 1
df_prior = pd.read_csv(dir_prior[0], skiprows=first_line, nrows=(5*12*24), parse_dates=['SETTLEMENTDATE'])

print(df_prior)


first_line = 0
with open(dir_post[0], newline='') as f:
    reader = csv.reader(f)
    for row in reader:
        if(row[8]) == "RRP":
            break
        first_line += 1
df_post =  pd.read_csv(dir_post[0], skiprows=first_line, nrows=(5*12*24), parse_dates=['SETTLEMENTDATE'])

print(df_post)

df = pd.concat([df_prior, df_post])
#df = pd.read_csv("data/price_data_csv/PUBLIC_PRICES_202106140000_collated.CSV", header=1)
print(df)
#df['SETTLEMENTDATE'] = pd.to_datetime(df['SETTLEMENTDATE'])



df = df.loc[df['REGIONID'] == region]

df = df.loc[df['SETTLEMENTDATE'] >= date_of_interest]
df = df.loc[df['SETTLEMENTDATE'] < date_of_interest + dt.timedelta(days=1)]
#df = df.loc[df['2'] == 2]
#df = df.loc[df['DREGION'] == "DREGION"]
 
list_of_headers = [
'SETTLEMENTDATE',
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

print(df)

df = df[list_of_headers]

df.to_csv("data/price_data_csv/" + str(region + "_" + date_of_interest.strftime('%Y%m%d') + "_true_prices.csv"))