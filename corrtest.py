import os
import pandas as pd
from scipy.stats import spearmanr, pearsonr
import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib import rc
from sklearn.linear_model import LinearRegression

cm = 1/2.54  # centimeters in inches

def transform_feat(feature_use):

    original_name = feature_use.replace("metar_", "").replace("traj_", "")
    new_name = original_name

    units_use = ""

    if new_name == "label_col":
        new_name = "Trajectory class"
        units_use = ""

    if new_name == "distance":
        new_name = "Diffusion distance"
        units_use = "m"

    if new_name == "length":
        new_name = "Length"
        units_use = "m"
    
    if new_name == "straightness":
        new_name = "Straightness"
    
    if new_name == "sinuosity2":
        new_name = "Sinuosity"
    
    if new_name == "fractal_dimension":
        new_name = "Fractal dimension"
    
    if new_name == "emax":
        new_name = "Maximum expected displacement"
    
    if new_name == "duration":
        new_name = "Duration"
        units_use = "s"
    
    if new_name == "speed":
        new_name = "Speed"
        units_use = "m/s"
    
    if new_name == "ff":
        new_name = "Wind speed"
        units_use = "m/s"
    
    if new_name == "acceleration":
        new_name = "Acceleration"
        units_use = "m / s^{2}"
    
    if new_name == "dc":
        new_name = "Direction change (arithmetic average)"
        units_use = ""
    
    if new_name == "sddc":
        new_name = "Direction change (standard deviation)"
        units_use = ""
    
    if new_name == "u":
        new_name = "Relative humidity"
        units_use = "\%"
    
    if new_name == "t":
        new_name = "Temperature"
        units_use = "\degree C"
    
    if new_name == "td":
        new_name = "Dew point"
        units_use = "\degree C"
    
    if new_name == "p":
        new_name = "Air pressure at sea level"
        units_use = "mmHg"
    
    if new_name == "p0":
        new_name = "Air pressure at the measuring station"
        units_use = "mmHg"
    
    new_lab = new_name
    if units_use != "":
        new_lab += " ($" + units_use + "$)"
    return new_lab.replace("at ", "at\n").replace("ge (", "ge\n(").replace(" displ", "\ndispl").replace(" stat", "\nstat")

dfr = pd.read_csv("corr.csv", index_col = False)
df = pd.read_csv("features_traj_new.csv", index_col = False)
df_var_keys = [c for c in list(df.keys()) if "filename" not in c]
if not os.path.isfile("corrtest.csv"):
    values_compare = {"var1": [], "var2": [], "test_type": [], "pvalue": [], "statistic": []}
    for ix1 in range(len(df_var_keys)):
        m1 = df_var_keys[ix1]
        p1 = df[m1]
        for ix2 in range(ix1 + 1, len(df_var_keys)):
            m2 = df_var_keys[ix2]
            p2 = df[m2]
            spearmanrv = spearmanr(p1, p2)
            pearsonrv = pearsonr(p1, p2)
            model = LinearRegression()
            model.fit([[x] for x in p1], [[y] for y in p2])
            r2s = model.score([[x] for x in p1], [[y] for y in p2])
            values_compare["var1"].append(m1)
            values_compare["var2"].append(m2)
            values_compare["test_type"].append("spearman")
            values_compare["pvalue"].append(spearmanrv.pvalue)
            values_compare["statistic"].append(spearmanrv.statistic)
            values_compare["var1"].append(m1)
            values_compare["var2"].append(m2)
            values_compare["test_type"].append("pearson")
            values_compare["pvalue"].append(pearsonrv.pvalue)
            values_compare["statistic"].append(pearsonrv.statistic)
            values_compare["var1"].append(m1)
            values_compare["var2"].append(m2)
            values_compare["test_type"].append("r2")
            values_compare["pvalue"].append(r2s)
            values_compare["statistic"].append(r2s)
    dfnew = pd.DataFrame(values_compare)
    dfnew.to_csv("corrtest.csv", index = False)
else:
    dfnew = pd.read_csv("corrtest.csv", index_col = False)

ix_dfnew = set()
ix_dfnew_spearman = set()
ix_dfnew_pearson = set()
ix_dfnew_r2 = set()
dicti_model = {m: [] for m in df_var_keys}
spvaluse = 0.5
for ix in range(len(dfnew["var1"])):
    m1 = dfnew["var1"][ix]
    m2 = dfnew["var2"][ix]
    t = dfnew["test_type"][ix]
    p = dfnew["pvalue"][ix]
    if p > 0.5 and "spearman" == t:
        ix_dfnew_spearman.add((m1, m2))
    if p > 0.5 and "pearson" == t:
        ix_dfnew_pearson.add((m1, m2))
    if p > 0.5 and "r2" == t:
        ix_dfnew_r2.add((m1, m2))
    if p > 0.5:
        ix_dfnew.add((m1, m2))
print(len(df_var_keys) * (len(df_var_keys) - 1) // 2)
print(len(ix_dfnew))
print(len(ix_dfnew_spearman))
print(len(ix_dfnew_pearson))
print(len(ix_dfnew_r2))

ix_df_newest = set()
for ix1 in range(len(dfr["label_col"])):
    for ix2 in range(ix1 + 1, len(dfr["label_col"])):
        m1 = df_var_keys[ix1]
        m2 = df_var_keys[ix2]
        p = dfr[m1][ix2]
        if p > 0.5 or p < -0.5:
            ix_df_newest.add((m1, m2))
print(len(ix_df_newest))

plt.rcParams["svg.fonttype"] = "none"
rc('font',**{'family':'Arial'})

SMALL_SIZE = 7
MEDIUM_SIZE = 7
BIGGER_SIZE = 7

plt.rc('font', size=SMALL_SIZE)          # controls default text sizes
plt.rc('axes', titlesize=SMALL_SIZE)     # fontsize of the axes title
plt.rc('axes', labelsize=MEDIUM_SIZE)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('ytick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('legend', fontsize=SMALL_SIZE)    # legend fontsize
plt.rc('figure', titlesize=BIGGER_SIZE)  # fontsize of the figure title

plt.figure(figsize = (29.7 / 1.5 * cm, 21 / 1.5 * cm), dpi = 300)
sns.heatmap(dfr, annot = True, fmt = '.2f', cbar_kws={'label': 'Correlation Meter'}, cmap="coolwarm")

plt.xlabel("Features")
plt.xticks(rotation=90)
plt.yticks(rotation=0)
plt.xticks([i + 0.5 for i in range(len(df_var_keys))], [transform_feat(l) for l in df_var_keys])
plt.yticks([])
plt.savefig("corrplot.png", bbox_inches = "tight")
plt.savefig("corrplot.pdf", bbox_inches = "tight")
plt.savefig("corrplot.svg", bbox_inches = "tight")
plt.close()