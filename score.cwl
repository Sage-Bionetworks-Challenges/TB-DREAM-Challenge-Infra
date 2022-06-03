#!/usr/bin/env cwl-runner
#
# Example score submission file
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

hints:
  DockerRequirement:
    dockerPull: python:3.8.8-slim-buster

inputs:
  - id: input_file
    type: File
  - id: goldstandard
    type: File
  - id: check_validation_finished
    type: boolean?

arguments:
  - valueFrom: score.py
  - valueFrom: $(inputs.input_file.path)
    prefix: -f
  - valueFrom: $(inputs.goldstandard.path)
    prefix: -g
  - valueFrom: results.json
    prefix: -r

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: score.py
        entry: |
          #!/usr/bin/env python
          import argparse
          import json
          from sklearn import metrics

          parser = argparse.ArgumentParser()
          parser.add_argument("-f", "--submissionfile", required=True, help="Submission File")
          parser.add_argument("-r", "--results", required=True, help="Scoring results")
          parser.add_argument("-g", "--goldstandard", required=True, help="Goldstandard for scoring")

          args = parser.parse_args()
          result = {}

          prediction_file_status = "SCORED"
          subdf = pd.read_csv(args.submissionfile)
          golddf = pd.read_csv(args.goldstandard)

          mergeddf = subdf.merge(golddf, on = ['filename'], how='left')
          #setosa : target class in data
          fpr, tpr, thresholds = metrics.roc_curve(mergeddf['label'], mergeddf['class_0_pp'], 
                                                    pos_label='setosa')
          auc_score = metrics.auc(fpr, tpr)
          result['score'] = auc_score

          with open(args.results, 'w') as o:
            o.write(json.dumps(result))
     
outputs:
  - id: results
    type: File
    outputBinding:
      glob: results.json

  - id: status
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['submission_status'])