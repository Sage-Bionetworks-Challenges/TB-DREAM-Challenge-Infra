#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
doc: Run a Docker submission.

requirements:
- class: InitialWorkDirRequirement
  listing:
  - $(inputs.docker_script)
- class: InlineJavascriptRequirement

inputs:
- id: submissionid
  type: int
- id: docker_repository
  type: string
  default: ""
- id: docker_digest
  type: string
  default: ""
- id: parentid
  type: string
- id: synapse_config
  type: File
- id: input_dir
  type: string
- id: time_limit
  type: int?
  inputBinding:
    prefix: --container_time_limit
- id: docker_script
  type: File
- id: store
  type: boolean?

outputs:
- id: predictions
  type: File?
  outputBinding:
    glob: predictions.csv
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

baseCommand: python3
arguments: 
- valueFrom: $(inputs.docker_script.path)
- prefix: -s
  valueFrom: $(inputs.submissionid)
- prefix: --docker_repository
  valueFrom: $(inputs.docker_repository)
- prefix: --docker_digest
  valueFrom: $(inputs.docker_digest)
- prefix: --store
  valueFrom: $(inputs.store)
- prefix: --parentid
  valueFrom: $(inputs.parentid)
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- prefix: -i
  valueFrom: $(inputs.input_dir)
