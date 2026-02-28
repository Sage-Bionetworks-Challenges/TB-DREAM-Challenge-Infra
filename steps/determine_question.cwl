#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: ExpressionTool
label: Get task number and groundtruth ID from queue number

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: queue
  type: string

outputs:
- id: task_number
  type: string
- id: gt_synid
  type: string

expression: |2-

  ${
    if(inputs.queue == "9615045"){
      return {
          task_number: "1",
          gt_synid: "syn43372449"
        };
    } else if (inputs.queue == "9615047") {
      return {
        task_number: "2",
        gt_synid: "syn43372436"
      };
    } else if (inputs.queue == "9615106") {
      return {
        task_number: "3",
        gt_synid: "syn43372449"
      };
    } else if (inputs.queue == "9615107") {
      return {
        task_number: "4",
        gt_synid: "syn43372436"
      };
    } else if (inputs.queue == "9615429") {
      return {
        task_number: "5",
        gt_synid: "syn52703865"
      };
    } else if (inputs.queue == "9615430") {
      return {
        task_number: "6",
        gt_synid: "syn52703865"
      };
    } else {
      throw 'invalid queue';
    }
  }