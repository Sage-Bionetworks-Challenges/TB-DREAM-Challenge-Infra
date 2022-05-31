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
    type: File?
  - id: entity_type
    type: string

arguments:
  - valueFrom: validate.py
  - valueFrom: $(inputs.input_file)
    prefix: -s
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
          parser = argparse.ArgumentParser()
          parser.add_argument("-r", "--results", required=True, help="validation results")
          parser.add_argument("-e", "--entity_type", required=True, help="synapse entity type downloaded")
          parser.add_argument("-s", "--submission_file", help="Submission File")

          args = parser.parse_args()
          
          if args.submission_file is None:
              prediction_file_status = "INVALID"
              invalid_reasons = ['Expected FileEntity type but found ' + args.entity_type]
          else:
              with open(args.submission_file,"r") as sub_file:
                  message = sub_file.read()
              invalid_reasons = []
              prediction_file_status = "VALIDATED"
              if not message.startswith("test"):
                  invalid_reasons.append("Submission must have test column")
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