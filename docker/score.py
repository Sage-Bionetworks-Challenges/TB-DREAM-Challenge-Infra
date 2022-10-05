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

import pandas as pd
from sklearn.metrics import (roc_auc_score,
                             average_precision_score,
                             confusion_matrix,
                             matthews_corrcoef)



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


def score(gold, pred):
    """
    Calculate metrics for: AUC-ROC, AUCPR, accuracy,
    sensitivity, specificity, and MCC (for funsies).
    """
    roc = roc_auc_score(gold['label'], pred['tb_status'])
    pr = average_precision_score(gold['label'], pred['tb_status'])
    tn, fp, fn, tp = confusion_matrix(gold['label'], pred['tb_status']).ravel()
    acc = (tp + tn) / (tp + fp + fn + tn)
    sens = tp / (tp + fn)
    spec = tn / (tn + fp)
    mcc = matthews_corrcoef(gold['label'], pred['tb_status'])

    return {
        'auc_roc': roc, 'auprc': pr,
        'accuracy': acc, 'sensitivity': sens,
        'specificity': spec, 'mcc': mcc
    }


def main():
    """Main function."""
    args = get_args()

    pred = pd.read_csv(args.predictions_file)
    gold = pd.read_csv(args.goldstandard_file)
    scores = score(gold, pred)

    with open(args.output, "w") as out:
        res = {
            "submission_status": "SCORED",
            **scores
        }
        out.write(json.dumps(res))


if __name__ == "__main__":
    main()
