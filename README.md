# Model-to-Data Workflow
This repository will serve as a template for the `CWL` workflow and tools required to set up a `model-to-data` challenge infrastructure.

For more information about the tools, refer to [ChallengeWorkflowTemplates](https://github.com/Sage-Bionetworks/ChallengeWorkflowTemplates).

## Workflow Steps

**Step** | **Description** 
--|--
`set_submitter_folder_permissions` | Grants admin user/team `download` permissions to the Docker submission log.
`set_admin_folder_permissions` | Grants admin user/team `download` permissions to the predictions file.
`get_docker_submission` | Downloads the submission's Docker image.
`get_docker_config` | Extracts the Synapse credentials and format into Docker config.
`download_goldstandard` | Downloads the goldstandard file.
`validate_docker` | Ensures the Docker submission image exists and <1 terabyte in size.
`email_docker_validation` | Sends an email notification to the partipant/team of the validation results. By default, an email will only be sent if there are errors.
`annotate_docker_validation_with_output` | Updates the submission status (`VALIDATED` if valid, else `INVALID`).
`check_docker_status` | Checks the submission status. If the status is `INVALID`, halt the workflow.
`run_docker` | Runs the Docker submission model.
`upload_results` | Uploads the predictions file.
`annotate_docker_upload_results` | Adds the `prediction_fileid` and `prediction_file_version` annotations to the submission.
`validate` | Validates the predictions file.
`email_validation` | Sends an email notification to the partipant/team of the validation results. By default, an email will only be sent if there are errors.
`annotate_validation_with_output` | Updates the submission status (`VALIDATED` if valid, else `INVALID`).
`check_status` | Checks the submission status. If the status is `INVALID`, halt the workflow.
`score` | Scores the predictions file.
`email_score` | Sends an email notification to the participant/team of the scoring results. By default, all scores are sent.
`annotate_submission_with_output` | Updates the submission status (`SCORED` if successful, else `INVALID`)

## Usage

### Requirements
* `pip3 install cwltool`
* A Synapse account/configuration file.  Learn more [here](https://docs.synapse.org/articles/client_configuration.html#for-developers)
* A Synapse Submission object ID.  Learn more [here](https://docs.synapse.org/articles/evaluation_queues.html#submissions)


### Configurations
**workflow.cwl** 

**Step** | **Description** | **Required?** | **Example**
--|--|--|--
`set_submitter_folder_permissions` | Provide the admin user ID or admin team ID for `principalid` | Yes | `valueFrom: "3379097"`
`set_admin_folder_permissions` | Provide the admin user ID or admin team ID for `principalid` | Yes | `valueFrom: "3379097"`
`download_goldstandard` | Update `synapseid` to the Synapse ID of the challenge's goldstandard | Yes | `valueFrom: "syn12345678"`
`email_docker_validation` | Set `errors_only` to `false` if an email notification about a valid submission should also be sent | No | `default: false`
`run_docker` | Set `store` to `false` if log files should be withheld from the participants | No | `default: false`
`run_docker` | Provide the absolute path to the data directory for `input_dir`; this directory will be mounted during the Docker submission run.  | Yes | `valueFrom: "/challenge_data"`
`email_validation` | Set `errors_only` to `false` if an email notification about a valid submission should also be sent | No | `default: false`
`email_score` | Add metrics and scores to `private_annotations` if they are to be withheld from the participants | No | `default: [primary_metric, primary_metric_value]`

**validate.cwl**

**Line** | **Description** | **Required?** | **Example**
--|--|--|--
`dockerPull: python:3.8.8-slim-buster` | Update the base image if the validation code is not Python | If code is not Python, yes | ` dockerPull: rocker/r-base:4.0.4`
`entry: \| [validation code]` | Remove the sample validation code and replace with validation code for the Challenge | Yes | --

* **NOTE:** expected annotations to write out are `submission_status` and `submission_errors`.

**score.cwl**

**Line** | **Description** | **Required?** | **Example**
--|--|--|--
`dockerPull: python:3.8.8-slim-buster` | Update the base image if the validation code is not Python | If code is not Python, yes | ` dockerPull: rocker/r-base:4.0.4`
`entry: \| [scoring code]` | Remove the sample scoring code and replace with scoring code for the Challenge | Yes | --

* **NOTE:** expected annotations to write out are `primary_metric`, `primary_metric_value`, and `submission_status`. If there is a secondary (tie-breaking) metric, include the `secondary_metric` and `secondary_metric_value` annotations as well.


### Example Run

```bash
cwltool workflow.cwl --submissionId 12345 \
                     --adminUploadSynId syn123 \
                     --submitterUploadSynId syn456 \
                     --workflowSynapseId syn789 \
                     --synaspeConfig ~/.synapseConfig
```
where:
* `submissionId`: Submission ID to run this workflow on
* `adminUploadSynId`: Synapse ID of Folder accessible by admin user/team
* `submitterUploadSynId`: Synapse ID of Folder accessible by submitter
* `workflowSynapseId`: Synapse ID of File that links to workflow archive
* `synapseConfig`: filepath to .synapseConfig file
