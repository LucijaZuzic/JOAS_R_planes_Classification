import os
import pandas as pd

df = pd.read_csv('LDZA.05.06.2017.27.06.2022.1.0.0.en.utf8.00000000.csv', skiprows = 6, sep = ";")

if not os.path.isdir("rp5_new"):
    os.makedirs("rp5_new")

dates_list = sorted(list(set([x.split(" ")[0] for x in df["Local time in Zagreb / Pleso (airport)"]])))
print(len(dates_list))

for date_one in dates_list:
    index_use = [ix for ix in range(len(df["Local time in Zagreb / Pleso (airport)"])) if date_one in df["Local time in Zagreb / Pleso (airport)"][ix]]
    print(date_one, len(index_use))
    dicti_new = dict()
    for col in df:
        new_col = [df[col][ix] for ix in index_use]
        dicti_new[col] = new_col
    df_new = pd.DataFrame(dicti_new)
    df_new.to_csv("rp5_new/LDZA." + date_one + "." + date_one + ".1.0.0.en.utf8.00000000.csv", index = False, sep = ";")