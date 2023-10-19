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
    } else if (inputs.queue == "9615106") {
      return {task_number: "3"};
    } else if (inputs.queue == "9615107") {
      return {task_number: "4"};
    } else if (inputs.queue == "9615429") {
      return {task_number: "5"};
    } else if (inputs.queue == "9615430") {
      return {task_number: "6"};
    } else {
      throw 'invalid queue';
    }
  }