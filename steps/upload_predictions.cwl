#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
doc: Upload a file to the given parent id on Synapse.

requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entryname: upload_file.py
    entry:
      $include: ../scripts/upload_file_to_synapse.py

inputs:
- id: infile
  type: File
- id: parentid
  type: string
- id: used_entity
  type: string
- id: executed_entity
  type: string
- id: synapse_config
  type: File
- id: check_docker_run_finished
  type: boolean?

outputs:
- id: uploaded_fileid
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['prediction_fileid'])
    loadContents: true
- id: uploaded_file_version
  type: int
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['prediction_file_version'])
    loadContents: true
- id: results
  type: File
  outputBinding:
    glob: results.json

baseCommand:
- python3
- upload_file.py
arguments:
- prefix: -f
  valueFrom: $(inputs.infile)
- prefix: -p
  valueFrom: $(inputs.parentid)
- prefix: -ui
  valueFrom: $(inputs.used_entity)
- prefix: -e
  valueFrom: $(inputs.executed_entity)
- prefix: -r
  valueFrom: results.json
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v3.1.1
