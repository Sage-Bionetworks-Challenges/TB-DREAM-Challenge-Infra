#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Validate predictions file

requirements:
  - class: InlineJavascriptRequirement


inputs:
  - id: input_file
    type: File
  - id: goldstandard
    type: File
  - id: task_number
    type: string

outputs:
  - id: results
    type: File
    outputBinding:
      glob: results.json
  - id: status
    type: string
    outputBinding:
      glob: results.json
      outputEval: $(JSON.parse(self[0].contents)['submission_status'])
      loadContents: true
  - id: invalid_reasons
    type: string
    outputBinding:
      glob: results.json
      outputEval: $(JSON.parse(self[0].contents)['submission_errors'])
      loadContents: true

baseCommand: validate.py
arguments:
  - prefix: -p
    valueFrom: $(inputs.input_file)
  - prefix: -g
    valueFrom: $(inputs.goldstandard.path)
  - prefix: -t
    valueFrom: $(inputs.task_number)
  - prefix: -o
    valueFrom: results.json

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn31472956/evaluation:v1
