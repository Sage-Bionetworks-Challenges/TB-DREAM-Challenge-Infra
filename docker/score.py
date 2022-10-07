#!/usr/bin/env python3
"""Score prediction file.

Task 1 and 2 will return the same metrics:
    - ROC curve
    - PR curve
    - accuracy
    - sensitivity
    - specificity
"""

import argparse
import json
import os
import glob

import pandas as pd
from sklearn.metrics import (roc_auc_score,
                             average_precision_score,
                             confusion_matrix,
                             matthews_corrcoef)

import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
import numpy as np
pandas2ri.activate()



def get_args():
    """Set up command-line interface and get arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--predictions_file",
                        type=str, required=True)
    parser.add_argument("-g", "--goldstandard_file",
                        type=str, required=True)
    parser.add_argument("-t", "--task", type=str, default="1")
    parser.add_argument("-o", "--output", type=str, default="results.json")
    return parser.parse_args()

def tpROC(df):
    r = robjects.r
    r['source']('/usr/local/bin/two_way_partial_AUC.R')

    sensitivity_bound = 0.8
    specificity_bound = 0.6

    # Loading the function we have defined in R.
    filter_proc_function_r = robjects.globalenv['pROCBasedTwoWayPartialAUC']
    pdf_2_r = robjects.conversion.py2rpy(df)
    
    df_r = filter_proc_function_r(pdf_2_r, sensitivity_bound, specificity_bound)
    return np.array(df_r)

def score(df):
    """
    Calculate metrics for: AUC-ROC, AUCPR, accuracy,
    sensitivity, specificity, and MCC (for funsies).
    """
    roc = roc_auc_score(df['label'], df['probability'])
    tp_roc = tpROC(df)

    return {
        'auc_roc': roc, 'tpAUC': tp_roc[0][0],
        'pAucSe': tp_roc[1][0], 'pAucSp': tp_roc[2][0]
    }


def main():
    """Main function."""
    args = get_args()

    pred = pd.read_csv(args.predictions_file)
    gold = pd.read_csv(args.goldstandard_file)

    df_combine = pred.merge(gold, on=['participant'], how='left')
    scores = score(df_combine)

    with open(args.output, "w") as out:
        res = {
            "submission_status": "SCORED",
            **scores
        }
        out.write(json.dumps(res))


if __name__ == "__main__":
    main()
