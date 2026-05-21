variable "stage" {
  description = "Environment, e.g. 'prd', 'int', 'dev', which could be the workspace name or environment"
  type        = string
}

variable "project" {
  description = "Project, which could be your organization name or abbreviation, e.g. 'cap' or 'cpb-cloud'. Might be the same as project_id"
  type        = string
}

variable "git_repository" {
  description = "Git repository from which the resources are deployed"
  type        = string
}

variable "main_lambda_file" {
  description = "Name of the main lambda .py file inside the 'src' folder"
  type        = string
  default     = "main"
}

variable "package_type" {
  description = "(Optional) Lambda deployment package type. Valid values are Zip and Image. Defaults to Zip."
  type        = string
  default     = "Zip"
}

variable "lambda_base_dir" {
  description = "(Optional) Full dir path to the base directory of the lambda (which includes the build.sh script and src/ dir"
  type        = string
  default     = ""
}

variable "lambda_common_dir" {
  description = "(Optional) Full dir path to the directory of shared lambda common code"
  type        = string
  default     = null
}

variable "lambda_source_dir" {
  description = "(Optional) Path to find source lambda files"
  default     = ""
}

variable "lambda_unique_function_name" {
  description = "Name of the lambda .py file"
}

variable "image_uri" {
  description = "(Optional) URI for lambda image. Must have implemented lambda runtime"
  type        = string
  default     = ""
}

variable "image_config_command" {
  description = "(Optional). Image configuration. Parameters that you want to pass in with entry_point. "
  type        = list(string)
  default     = null
}

variable "image_config_entry_point" {
  description = "(Optional). Image configuration. Entry point to your application, which is typically the location of the runtime executable."
  type        = list(string)
  default     = null
}

variable "image_config_working_directory" {
  description = "(Optional). Image configuration. Working directory."
  type        = string
  default     = null
}

variable "reserved_concurrent_executions" {
  description = "Number of reserved concurrent executions which can not be consumed by other functions within the account. Default is unreserved (= -1)"
  type        = number
  default     = -1
}

variable "runtime" {
  description = "(Optional) The languange/engine under which Lambda should run; see https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime"
  type        = string
  default     = "python3.8"
}

variable "handler" {
  description = "(Optional) The name of the function handler inside the lambda main file"
  type        = string
  default     = ""
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds"
  default     = "900"
}

variable "memory_size" {
  default = 128
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version"
  default     = true
}

variable "lambda_env_vars" {
  type        = map(string)
  description = "Environmental variables to expose to Lambda function"
}

variable "lambda_layers" {
  description = "(Optional) List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function"
  type        = list(string)
  default     = null
}

variable "attach_additional_policy" {
  default = false
}

variable "additional_policy" {
  description = "An addional policy document (JSON) to attach to the Lambda function"
  default     = ""
}

variable "logs_kms_key_arn" {
  description = "ARN to the KMS key which lambda should be using to decrypt and encrypt environmental variables"
}

variable "ssm_param_resource_arn" {
  description = "ARN of SSM parameter to retrieve; for example, DB password"
  default     = "*"
}

variable "lambda_description" {
  default = ""
}

variable "lambda_log_retention_period" {
  description = "Days to retain the logs"
  default     = 7
}

variable "security_group_ids" {
  description = "Optional variable, use if you want to configure Lambda function to be executed inside a specific VPC"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Optional variable, use if you want to configure Lambda function to be executed inside a specific VPC"
  type        = list(string)
  default     = []
}

variable "dead_letter_config_target_arn" {
  default = ""
}

variable "use_dead_letter_config_target_arn" {
  default = false
}

variable "tags_lambda" {
  description = "Instance specific Tags for lambda"
  type        = map(string)
  default     = {}
}

variable "artifact_bucket_name" {
  description = "(Optional) S3 Bucket where artifacts are published"
  type        = string
  default     = ""
}

variable "artifacts_prefix" {
  description = "(Optional) S3 bucket prefix that will hold artifacts"
  type        = string
  default     = "artifacts"
}

variable "enable" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "order" {
  default     = []
  type        = list(string)
  description = "Order of label components"
}

variable "provisioned_concurrency" {
  description = "Pre-provisions capacity. Only use when there is the requirement since it can accumulate costs rapidly. https://docs.aws.amazon.com/lambda/latest/dg/configuration-concurrency.html"
  default     = 0
}

variable "external_trigger" {
  description = "External trigger to force redeploy of the lambda function together with their resources."
  type        = string
  default     = ""
}

variable "region" {
  description = "The region for which the lambda should have EC2 permissions for. In case you can not specify the region a wildcard will be placed"
  type        = string
}

variable "xray_mode" {
  type        = string
  default     = "PassThrough"
  description = "(Optional) Mode defining xray tracing. PassThrough to trace the function only if X-Ray is enabled in an upstream service. Active to respect any tracing header, but if a tracing request is missing it automatically samples invocation requests"
}

variable "suppress_zip_output" {
  description = "Whether to suppress the log output of the zip command ([...] adding: xx/xx [...] (deflated yy%))"
  type        = bool
  default     = false
}

variable "lambda_role_name" {
  description = <<-EOT
    If you prefer injecting your IAM Role for the lambda function to use instead of
    having the module create one for you, add the IAM Role name here.
    Make sure your role's trust policy allows sts:AssumeRole from AWS
    Service lambda.amazonaws.com.
    EOT
  type        = string
  default     = null
}

variable "ephemeral_storage" {
  description = "The amount of ephemeral storage to use in MB. Default is 512 (lower not possible), at max 10240 is available"
  type        = number
  default     = 512
}
