#!/usr/bin/env cwl-runner
#
# Example validate submission file
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
  - id: entity_type
    type: string

arguments:
  - valueFrom: validate.py
  - valueFrom: $(inputs.input_file)
    prefix: -p
  - valueFrom: $(inputs.goldstandard.path)
    prefix: -g
  - valueFrom: $(inputs.entity_type)
    prefix: -e
  - valueFrom: results.json
    prefix: -r

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: validate.py
        entry: |
          #!/usr/bin/env python
          import argparse
          import json
          import os

          parser = argparse.ArgumentParser()
          parser.add_argument("-r", "--results", required=True, help="validation results")
          parser.add_argument("-g", "--goldstandard_file", type=str, help="gold standard")
          parser.add_argument("-e", "--entity_type", required=True, help="synapse entity type downloaded")
          parser.add_argument("-p", "--predictions_file", help="Submission File")

          args = parser.parse_args()
          
          if args.predictions_file is None:
              prediction_file_status = "INVALID"
              invalid_reasons = ['Expected FileEntity type but found ' + args.entity_type]
          else:
              invalid_reasons = []
              prediction_file_status = "VALIDATED"

              name, extension = os.path.splitext(args.predictions_file)
              if extension != '.csv':
                  invalid_reasons.append("Submission must be a csv file")
                  prediction_file_status = "INVALID"

              else:
                  with open(args.predictions_file,"r") as sub_file:
                      message = sub_file.read()
                  
                  if not message.startswith("filename,prediction"):
                      invalid_reasons.append("Submission must have filename and prediction column")
                      prediction_file_status = "INVALID"
          result = {'submission_errors': "\n".join(invalid_reasons),
                    'submission_status': prediction_file_status}
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

  - id: invalid_reasons
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['submission_errors'])