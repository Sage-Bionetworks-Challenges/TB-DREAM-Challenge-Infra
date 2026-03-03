#!/usr/bin/env python
import argparse
import json

import synapseclient

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--infile", required=True, help="file to upload")
    parser.add_argument(
        "-p", "--parentid", required=True, help="Synapse parent for file"
    )
    parser.add_argument(
        "-ui", "--used_entityid", required=False, help="id of entity 'used' as input"
    )
    parser.add_argument(
        "-uv",
        "--used_entity_version",
        required=False,
        help="version of entity 'used' as input",
    )
    parser.add_argument(
        "-e",
        "--executed_entity",
        required=False,
        help="Syn ID of workflow which was executed",
    )
    parser.add_argument("-r", "--results", required=True, help="Results of file upload")
    parser.add_argument(
        "-c", "--synapse_config", required=True, help="credentials file"
    )
    args = parser.parse_args()
    syn = synapseclient.Synapse(configPath=args.synapse_config)
    syn.login()
    file = synapseclient.File(path=args.infile, parent=args.parentid)
    try:
        file = syn.store(
            file,
            used={
                "reference": {
                    "targetId": args.used_entityid,
                    "targetVersionNumber": args.used_entity_version,
                }
            },
            executed=args.executed_entity,
        )
        fileid = file.id
        fileversion = file.versionNumber
    except Exception:
        fileid = ""
        fileversion = 0
    results = {"prediction_fileid": fileid, "prediction_file_version": fileversion}
    with open(args.results, "w") as o:
        o.write(json.dumps(results))
