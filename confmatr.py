import numpy as np
import pandas as pd

mode_max = {
    "FP": False,
    "TP": True,
    "FN": False,
    "TN": True,
    "TPR": True,
    "FNR": False,
    "TNR": True,
    "FPR": False,
    "PPV": True,
    "FDR": False,
    "NPV": True,
    "FOR": False,
    "Acc": True,
    "BA": True,
    "F1": True,
    "DR (P)": True,
    "DR (N)": True,
    "DP (P)": True,
    "DP (N)": True,
    "P (P)": True,
    "P (N)": True
}

def calculate_conf_matrix(actual, predicted):
    tp = 0
    fp = 0
    tn = 0
    fn = 0
    for ix in range(len(actual)):
        if actual[ix] == 1:
            if predicted[ix] == 1:
                tp += 1
            else:
                fn += 1
        else:
            if predicted[ix] == -1:
                tn += 1
            else:
                fp += 1
    dicti_metrics = {"TP": tp, "TN": tn, "FP": fp, "FN": fn}
    return dicti_metrics

def calculate_metrics(metric_set):
    tp, tn, fp, fn = metric_set["TP"], metric_set["TN"], metric_set["FP"], metric_set["FN"]
    tpr = "NA"
    fnr = "NA"
    if tp + fn > 0:
        tpr = tp / (tp + fn)
        fnr = 1 - tpr
    tnr = "NA"
    fpr = "NA"
    if tn + fp > 0:
        tnr = tn / (tn + fp)
        fpr = 1 - tnr
    ppv = "NA"
    fdr = "NA"
    if tp + fp > 0:
        ppv = tp / (tp + fp)
        fdr = 1 - ppv
    npv = "NA"
    for_new = "NA"
    if tn + fn > 0:
        npv = tn / (tn + fn)
        for_new = 1 - npv
    prev_y = (tp + fn) / (tp + fp + fn + tn)
    det_prev_y = (tp + fp) / (tp + fp + fn + tn)
    prev_n = (tn + fp) / (tp + fp + fn + tn)
    det_prev_n = (tn + fn) / (tp + fp + fn + tn)
    dr_y = tp / (tp + fp + fn + tn)
    dr_n = tn / (tp + fp + fn + tn)
    acc = (tp + tn) / (tp + fp + fn + tn)
    ba = "NA"
    if tpr != "NA" and tnr != "NA":
        ba = (tpr + tnr) / 2
    f1 = "NA"
    if ppv != "NA" and tpr != "NA" and ppv + tpr > 0:
        f1 = 2 * ppv * tpr / (ppv + tpr)
    return {"TPR": tpr,
            "FNR": fnr,
            "TNR": tnr,
            "FPR": fpr,
            "PPV": ppv,
            "FDR": fdr,
            "NPV": npv,
            "FOR": for_new,
            "DR (P)": dr_y,
            "DR (N)": dr_n,
            "DP (P)": det_prev_y,
            "DP (N)": det_prev_n,
            "P (P)": prev_y,
            "P (N)": prev_n,
            "Acc": acc,
            "BA": ba,
            "F1": f1}

def print_a_model(values_compare, short_model, smodels, code = ""):
    print("\t\t\multicolumn{" + str(len(smodels) + 1) + "}{|c|}{" + code + "} \\\\ \\hline")
    for key_val in values_compare:
        str_pr = key_val
        ix = 0
        while values_compare[key_val][smodels[ix]] == "NA":
            ix += 1
        best_val = values_compare[key_val][smodels[ix]]
        if key_val != "Model":
            for model in smodels:
                if key_val in mode_max and mode_max[key_val]:
                    if values_compare[key_val][model] != "NA" and values_compare[key_val][model] > best_val:
                        best_val = values_compare[key_val][model]
                else:
                    if values_compare[key_val][model] != "NA" and values_compare[key_val][model] < best_val:
                        best_val = values_compare[key_val][model]
        for model in smodels:
            v = values_compare[key_val][model]
            if key_val == "Model":
                str_pr += " & " + short_model[v.split("_")[0]]
                continue
            if v != "NA":
                if v == best_val and key_val in mode_max:
                    if key_val not in ["FP", "TP", "FN", "TN"]:
                        v = "$\\mathbf{" + str(np.round(v * 100, 2)) + "}$"
                    else:
                        v = "$\\mathbf{" + str(v) + "}$"
                else:
                    if key_val not in ["FP", "TP", "FN", "TN"]:
                        v = "$" + str(np.round(v * 100, 2)) + "$"
                    else:
                            v = "$" + str(v) + "$"
            str_pr += " & " + v
        print("\t\t" + str_pr + " \\\\ \\hline")

df_test = pd.read_csv("predictions_test_new.csv", index_col = False)
df_test_keys = list(df_test.keys())

values_compare = {"Model": dict()}
for ix1 in [0]:
    m1 = df_test_keys[ix1]
    p1 = df_test[m1]
    for ix2 in range(ix1 + 1, len(df_test_keys)):
        m2 = df_test_keys[ix2]
        values_compare["Model"][m2] = m2
        p2 = df_test[m2]
        metric_set = calculate_conf_matrix(p1, p2)
        for m in metric_set:
            if m not in values_compare:
                values_compare[m] = dict()
            values_compare[m][m2] = metric_set[m]
        mtr = calculate_metrics(metric_set)
        for m in mtr:
            if m not in values_compare:
                values_compare[m] = dict()
            values_compare[m][m2] = mtr[m]

short_model = {
    "k-NN": "k-NN",
    "Linear SVM": "L SVM",
    "RBF SVM": "RBF SVM",
    "Gaussian Process": "GP",
    "Decision Tree": "DT",
    "Random Forest": "RF",
    "Naive Bayes": "NB",
    "Multilayer Perceptron": "MLP",
    "AdaBoost": "AB",
    "Quadratic Discriminant Analysis": "QDA",
}

ks = set([x.split("_")[0] for x in df_test_keys])
print_a_model(values_compare, short_model, [m for m in df_test_keys if "all" in m], "all")
print_a_model(values_compare, short_model, [m for m in df_test_keys if "no_METAR" in m], "no_METAR")
print_a_model(values_compare, short_model, [m for m in df_test_keys if "METAR" in m and "no_METAR" not in m], "METAR")
print_a_model(values_compare, short_model, [m for m in df_test_keys if "distance" in m and "dc" in m], "traj_distance_traj_dc")