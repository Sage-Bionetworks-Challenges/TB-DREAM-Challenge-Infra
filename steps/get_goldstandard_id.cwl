#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: ExpressionTool
label: Get Synase ID to goldstandard file based on task

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: task_number
  type: string

outputs:
- id: synid
  type: string

expression: |

  ${
    if(inputs.task_number == "1") {
      return {synid: "syn43372449"};
    } else if (inputs.task_number == "2") {
      return {synid: "syn43372436"};
    } else if (inputs.task_number == "3") {
      return {synid: "syn43372449"};
    } else if (inputs.task_number == "4") {
      return {synid: "syn43372436"};
    }
  }
