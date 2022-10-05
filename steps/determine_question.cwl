#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: ExpressionTool
label: Get task number (1 or 2) based on queue IDs

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: queue
  type: string

outputs:
- id: task_number
  type: string

expression: |

  ${
    if(inputs.queue == "9615045"){
      return {task_number: "1"};
    } else if (inputs.queue == "9615047") {
      return {task_number: "2"};
    } else {
      throw 'invalid queue';
    }
  }