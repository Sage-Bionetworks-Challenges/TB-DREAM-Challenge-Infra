#!/usr/bin/env python3
"""Validate prediction file.

- Task:  TB vs No TB
"""

import argparse
import json

import pandas as pd
import numpy as np

COLS = {
        'participant': str,
        'tb_status': np.int8,
        'probability': np.float64
        }


def get_args():
    """Set up command-line interface and get arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--predictions_file",
                        type=str, required=True)
    parser.add_argument("-g", "--goldstandard_file",
                        type=str, required=True)
    parser.add_argument("-t", "--task", type=str, default="1")
    parser.add_argument("-o", "--output", type=str)
    return parser.parse_args()


def check_dups(pred):
    """Check for duplicate participant IDs."""
    duplicates = pred.duplicated(subset=['participant'])
    if duplicates.any():
        return (
            f"Found {duplicates.sum()} duplicate participant ID(s): "
            f"{pred[duplicates].participant.to_list()}"
        )
    return ""


def check_missing_ids(gold, pred):
    """Check for missing participant IDs."""
    pred = pred.set_index('participant')
    missing_ids = gold.index.difference(pred.index)
    if missing_ids.any():
        return (
            f"Found {missing_ids.shape[0]} missing participant ID(s): "
            f"{missing_ids.to_list()}"
        )
    return ""


def check_unknown_ids(gold, pred):
    """Check for unknown participant IDs."""
    pred = pred.set_index('participant')
    unknown_ids = pred.index.difference(gold.index)
    if unknown_ids.any():
        return (
            f"Found {unknown_ids.shape[0]} unknown participant ID(s): "
            f"{unknown_ids.to_list()}"
        )
    return ""


def check_nan_values(pred):
    """Check for NAN predictions."""
    missing_probs = pred.probability.isna().sum()
    if missing_probs:
        return (
            f"'probability' column contains {missing_probs} NaN value(s)."
        )
    return ""


def check_binary_values(pred):
    """Check that binary label are only 0 and 1."""
    colname = pred.filter(regex='tb_status').columns[0]
    if not pred.loc[:, colname].isin([0, 1]).all():
        return f"'{colname}' column should only contain 0 and 1."
    return ""


def check_prob_values(pred):
    """Check that probabilities are between [0, 1]."""
    if (pred.probability < 0).any() or (pred.probability > 1).any():
        return "'probability' column should be between [0, 1] inclusive."
    return ""


def validate(gold_file, pred_file):
    """Validate predictions file against goldstandard."""
    errors = []

    gold = pd.read_csv(gold_file,
                       index_col="participant")
    try:
        pred = pd.read_csv(pred_file,
                           usecols=COLS,
                           dtype=COLS,
                           float_precision='round_trip')
    except ValueError as err:
        errors.append(
            f"Invalid column names and/or types: {str(err)}. "
            f"Expecting: {str(COLS)}."
        )
    else:
        errors.append(check_dups(pred))
        errors.append(check_missing_ids(gold, pred))
        errors.append(check_unknown_ids(gold, pred))
        errors.append(check_nan_values(pred))
        errors.append(check_binary_values(pred))
        errors.append(check_prob_values(pred))
    return errors


def main():
    """Main function."""
    args = get_args()

    invalid_reasons = validate(
        gold_file=args.goldstandard_file,
        pred_file=args.predictions_file
    )

    invalid_reasons = "\n".join(filter(None, invalid_reasons))
    status = "INVALID" if invalid_reasons else "VALIDATED"

    # truncate validation errors if >500 (character limit for sending email)
    if len(invalid_reasons) > 500:
        invalid_reasons = invalid_reasons[:496] + "..."
    res = json.dumps({
        "submission_status": status,
        "submission_errors": invalid_reasons
    })

    if args.output:
        with open(args.output, "w") as out:
            out.write(res)
    else:
        print(res)


if __name__ == "__main__":
    main()