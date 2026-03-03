#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: CODA TB Chalenge evaluation workflow

requirements:
  - class: StepInputExpressionRequirement

inputs:
  adminUploadSynId:
    label: Synapse Folder ID accessible by an admin
    type: string
  submissionId:
    label: Submission ID
    type: int
  submitterUploadSynId:
    label: Synapse Folder ID accessible by the submitter
    type: string
  synapseConfig:
    label: filepath to .synapseConfig file
    type: File
  workflowSynapseId:
    label: Synapse File ID that links to the workflow
    type: string
  organizersId:
    label: User or team ID for challenge organizers
    type: string
    default: "3449996"

outputs: []

steps:

  set_submitter_folder_permissions:
    doc: >
      Give challenge organizers `download` permissions to the docker logs
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/set_permissions.cwl
    in:
      - id: entityid
        source: "#submitterUploadSynId"
      - id: principalid
        source: "#organizersId"
      - id: permissions
        valueFrom: "download"
      - id: synapse_config
        source: "#synapseConfig"
    out: []

  set_admin_folder_permissions:
    doc: >
      Give challenge organizers `download` permissions to the private submission folder
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/set_permissions.cwl
    in:
      - id: entityid
        source: "#adminUploadSynId"
      - id: principalid
        source: "#organizersId"
      - id: permissions
        valueFrom: "download"
      - id: synapse_config
        source: "#synapseConfig"
    out: []

  get_docker_submission:
    doc: Get information about Docker submission, e.g. image name and digest
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/get_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath
      - id: docker_repository
      - id: docker_digest
      - id: entity_id
      - id: entity_type
      - id: evaluation_id
      - id: results

  determine_question:
    run: steps/determine_question.cwl
    in:
      - id: queue
        source: "#get_docker_submission/evaluation_id"
    out:
      - id: task_number
      - id: gt_synid
      - id: input_dir

  download_goldstandard:
    doc: Download groundtruth file
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks-Workflows/cwl-tool-synapseclient/v1.4/cwl/synapse-get-tool.cwl
    in:
      - id: synapseid
        source: "#determine_question/gt_synid"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath

  run_docker:
    doc: >
      Run the participant Docker container against the input data to generate predictions
    run: steps/run-docker.cwl
    in:
      - id: docker_repository
        source: "#get_docker_submission/docker_repository"
      - id: docker_digest
        source: "#get_docker_submission/docker_digest"
      - id: submissionid
        source: "#submissionId"
      - id: parentid
        source: "#submitterUploadSynId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: store
        default: true
      - id: input_dir
        source: "#determine_question/input_dir"
      - id: time_limit
        default: 10800  # 3 hours in seconds
      - id: docker_script
        default:
          class: File
          location: "scripts/run_docker.py"
    out:
      - id: predictions
      - id: results
      - id: status
      - id: invalid_reasons

  send_docker_run_status:
    doc: Send email notification about container run results
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/validate_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status
        source: "#run_docker/status"
      - id: invalid_reasons
        source: "#run_docker/invalid_reasons"
      - id: errors_only
        valueFrom: "true"
    out: [finished]

  annotate_docker_run_results:
    doc: >
      Add `submission_status` and `submission_errors` annotations to the
      submission based on the container run results
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#run_docker/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  check_docker_run_status:
    doc: >
      Check the status of the container run; if 'INVALID', throw an
      exception to stop the workflow at this step. That way, the
      workflow will not attempt to evaluate a non-existent predictions
      file.
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#run_docker/status"
      - id: previous_annotation_finished
        source: "#annotate_docker_run_results/finished"
      - id: previous_email_finished
        source: "#send_docker_run_status/finished"
    out: [finished]

  upload_generated_predictions:
    doc: Upload the generated predictions file to the private folder
    run: steps/upload_predictions.cwl
    in:
      - id: infile
        source: "#run_docker/predictions"
      - id: parentid
        source: "#adminUploadSynId"
      - id: used_entity
        source: "#download_submission/entity_id"
      - id: executed_entity
        source: "#workflowSynapseId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: check_docker_run_finished
        source: "#check_docker_run_status/finished"
    out:
      - id: uploaded_fileid
      - id: uploaded_file_version
      - id: results

  annotate_docker_upload_results:
    doc: >
      Add annotations about the uploaded predictions file to the submission
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#upload_generated_predictions/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
      - id: previous_annotation_finished
        source: "#annotate_docker_run_results/finished"
    out: [finished]

  validate:
    doc: Validate format of generated predictions file, prior to scoring
    run: steps/validate.cwl
    in:
      - id: input_file
        source: "#run_docker/predictions"
      - id: goldstandard
        source: "#download_goldstandard/filepath"
      - id: task_number
        source: "#determine_question/task_number"
    out:
      - id: results
      - id: status
      - id: invalid_reasons
  
  send_validation_results:
    doc: Send email of the validation results to the submitter
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/validate_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status
        source: "#validate/status"
      - id: invalid_reasons
        source: "#validate/invalid_reasons"
      - id: errors_only
        default: false
    out: [finished]

  add_validation_annots:
    doc: Update the submission annotations with validation results
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#validate/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
      - id: previous_annotation_finished
        source: "#annotate_docker_upload_results/finished"
    out: [finished]

  check_validation_status:
    doc: >
      Check the validation status of the submission; if 'INVALID', throw an
      exception to stop the workflow at this step. That way, the workflow
      will not attempt scoring invalid predictions file.
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#validate/status"
      - id: previous_annotation_finished
        source: "#add_validation_annots/finished"
      - id: previous_email_finished
        source: "#send_validation_results/finished"
    out: [finished]

  score:
    run: steps/score.cwl
    in:
      - id: input_file
        source: "#run_docker/predictions"
      - id: goldstandard
        source: "#download_goldstandard/filepath"
      - id: task_number
        source: "#determine_question/task_number"
      - id: check_validation_finished 
        source: "#check_validation_status/finished"
    out:
      - id: results
      - id: status
      
  send_score_results:
    doc: >
      Send email of the evaluation status (optionally with scores) to the submitter
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/score_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: results
        source: "#score/results"
      - id: private_annotations
        default: ['auc_roc', 'tpAUC', 'pAucSe', 'pAucSp']
    out: []

  add_score_annots:
    doc: >
      Update `submission_status` and add the scoring metric annotations
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#score/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
      - id: previous_annotation_finished
        source: "#add_validation_annots/finished"
    out: [finished]
 
  check_score_status:
    doc: >
      Check the scoring status of the submission; if 'INVALID', throw an
      exception so that final status is 'INVALID' instead of 'ACCEPTED'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#score/status"
      - id: previous_annotation_finished
        source: "#add_score_annots/finished"
    out: [finished]
