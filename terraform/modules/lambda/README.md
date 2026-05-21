# Terraform Module: AWS LAMBDA
Current extracted AWS Lambda module(s) directly from `cap-consumer-ap` repository.

## Requirements

Currently, the CAP project uses different SSH Deploy Keys, each unique to its module repo. For this reason, referencing to the current module from any of the CAP related projects, the developer needs to setup an entry in the SSH Config to create a unique alias for the module.

## Current Usage

### SSH Config

In the scenario where the Private SSH Deploy Key is stored in `~/.ssh/cap-tf-module-aws-lambda-vpc`, then the entry in the SSH config file (typically in `~/.ssh/config`) could look like:

```
Host cap-tf-module-aws-lambda-vpc
  HostName github.com
  User git
  IdentityFile ~/.ssh/cap-tf-module-aws-lambda-vpc
```

Doing so, will let any application using SSH (including Terraform) refer to the module with `cap-tf-module-aws-lambda-vpc` as hostname instead of `github.com`. For example, the developer could now download the repository with:

```
git clone cap-tf-module-aws-lambda-vpc:vwdfive/cap-tf-module-aws-lambda-vpc.git
```

### Module usage

#### Lambda Requirements

The module assumes 2x important elements:
1) `lambda_base_dir` which contains a `build.sh`
2) a `src` directory with a `main.py` file

```
lambda_dir/
├── build.sh
├── requirements.txt
└── src
    └── main.py
```

The lambda execution logic is as follows:
1. Change directory into the base lambda directory (`lambda_dir`).
2. Execute build.sh to follow whatever steps are needed to package the lambda (e.g. install requirements, etc.)
3. Zip all contents of the packaged directory into a `.zip` file which is then uploaded to S3.
4. Name of the Zip file is composed of the `md5` of the `main.py` file. This allows to trigger lambda updates, in case the lambda source changes.

This process allows for the developer of each lambda to compose what steps are needed before zipping the lambda and storing it in an S3 bucket.

#### Usage

The current implementation of AWS Lambda modules in the original `cap-consumer-ap` repository contains 1x different module for each AWS lambda type.
For this reason, all modules were copied into separate directories, so they can still be referenced by said repository and usage would be as follows:
(notice usage of the repo path of the module + tag version)

```hcl-terraform
module "inspector_report_lambda" {

  source = "git::ssh://cap-tf-module-aws-lambda-vpc/vwdfive/cap-tf-module-aws-lambda-vpc.git?ref=tags/<insert-tag-here>"

  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
  environment    = var.environment
  project        = var.project

  additional_policy = data.aws_iam_policy_document.inspector_report_lambda_policy.json
  attach_policy     = true

  lambda_unique_function_name = var.lambda_inspector_report_function_name
  artifact_bucket_name        = module.cap_artifacts_bucket.s3_bucket
  runtime                     = "python3.6"
  handler                     = "handler"
  main_lambda_file            = "main"
  package_type                = "Zip"
  lambda_base_dir             = "${path.module}/../../../etl/lambdas/inspector_report"
  lambda_source_dir           = "${path.module}/../../../etl/lambdas/inspector_report/src"
  memory_size                 = 1000
  timeout                     = 300
  logs_kms_key_arn            = module.logs_bucket.aws_kms_key_arn

  lambda_env_vars = {
    PROJECT     = var.project
    ENVIRONMENT = var.environment
    STAGE       = var.environment
    TEMPLATE_ARNS = join(",", [
      join("", aws_inspector_assessment_template.cap_assessment_template.*.arn),
      join("", aws_inspector_assessment_template.cap_on_dap_assessment_template.*.arn)
    ])
    EMAIL_SENDER = "Evghenii Cvasniuc <evghenii.cvasniuc@volkswagen.de>"
    // please do NOT use space between the email addresses in email_recipient
    // the '/' is for distinguishing the To addresses and Cc addresses
    EMAIL_RECIPIENT = "${join(",", values(var.report_recipients.vw))}/${join(",", values(var.report_recipients.deloitte))}"
  }

  tags_lambda = {
    KST = var.tag_KST
  }
}
```

**NOTE**: notice the reference to the hostname (after ssh://) to `cap-tf-module-aws-lambda-vpc` instead of `github.com`. This is only possible due to the previously described configuration in the SSH Config file.

## Future Usage

After complete module extraction, all AWS Lambda modules will be combined into a single module, where one of the attributes will refer to the type of module in usage.
Biggest reason for not doing this for previously created buckets at the same time of module extraction is to prevent unintended changes to existing resources and separation of concerns (module extraction vs. module improvements)

## Migration from `0.1.0` to `0.1.1`
1. Update scripts where this module is used to refer to version: `0.2.0`
1. Migrate existing lambdas from previous resource addresses, e.g.
    * `module.x.aws_lambda_function.lambda`
    * `module.x.aws_lambda_function.lambda_with_dlq`
    * `module.x.aws_lambda_function.lambda_with_vpc`
    * `module.x.aws_lambda_function.lambda_with_vpc_and_dlq`

    # TODO:!!!
    to new resource addresses, e.g.
    * `module.x.aws_lambda_function.lambda`

   ```
   terraform state mv module.x.aws_lambda_function.lambda module.x.aws_lambda_function.lambda

   # or using make for cap-consumer-ap/terraform/environments/cap-etl/esb-s3-sync:
   export ENVIRONMENT=cap-etl/esb-s3-sync RESOURCE=module.lambda.aws_lambda_function.lambda TARGET=module.lambda.aws_lambda_function.lambda
   make state-mv
   ```

# Module Spec
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda_label"></a> [lambda\_label](#module\_lambda\_label) | git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label?ref=tags/0.3.0 |  |
| <a name="module_lambda_policy_label"></a> [lambda\_policy\_label](#module\_lambda\_policy\_label) | git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label?ref=tags/0.3.0 |  |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.this_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.this_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_inline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_xray_write_only_process](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_provisioned_concurrency_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_provisioned_concurrency_config) | resource |
| [aws_s3_object.lambda_artifact_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [null_resource.build_upload](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ec2policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.injected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_policy"></a> [additional\_policy](#input\_additional\_policy) | An addional policy document (JSON) to attach to the Lambda function | `string` | `""` | no |
| <a name="input_artifact_bucket_name"></a> [artifact\_bucket\_name](#input\_artifact\_bucket\_name) | (Optional) S3 Bucket where artifacts are published | `string` | `""` | no |
| <a name="input_artifacts_prefix"></a> [artifacts\_prefix](#input\_artifacts\_prefix) | (Optional) S3 bucket prefix that will hold artifacts | `string` | `"artifacts"` | no |
| <a name="input_attach_additional_policy"></a> [attach\_additional\_policy](#input\_attach\_additional\_policy) | n/a | `bool` | `false` | no |
| <a name="input_dead_letter_config_target_arn"></a> [dead\_letter\_config\_target\_arn](#input\_dead\_letter\_config\_target\_arn) | n/a | `string` | `""` | no |
| <a name="input_enable"></a> [enable](#input\_enable) | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| <a name="input_ephemeral_storage"></a> [ephemeral\_storage](#input\_ephemeral\_storage) | The amount of ephemeral storage to use in MB. Default is 512 (lower not possible), at max 10240 is available | `number` | `512` | no |
| <a name="input_external_trigger"></a> [external\_trigger](#input\_external\_trigger) | External trigger to force redeploy of the lambda function together with their resources. | `string` | `""` | no |
| <a name="input_git_repository"></a> [git\_repository](#input\_git\_repository) | Git repository from which the resources are deployed | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | (Optional) The name of the function handler inside the lambda main file | `string` | `""` | no |
| <a name="input_image_config_command"></a> [image\_config\_command](#input\_image\_config\_command) | (Optional). Image configuration. Parameters that you want to pass in with entry\_point. | `list(string)` | `null` | no |
| <a name="input_image_config_entry_point"></a> [image\_config\_entry\_point](#input\_image\_config\_entry\_point) | (Optional). Image configuration. Entry point to your application, which is typically the location of the runtime executable. | `list(string)` | `null` | no |
| <a name="input_image_config_working_directory"></a> [image\_config\_working\_directory](#input\_image\_config\_working\_directory) | (Optional). Image configuration. Working directory. | `string` | `null` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | (Optional) URI for lambda image. Must have implemented lambda runtime | `string` | `""` | no |
| <a name="input_lambda_base_dir"></a> [lambda\_base\_dir](#input\_lambda\_base\_dir) | (Optional) Full dir path to the base directory of the lambda (which includes the build.sh script and src/ dir | `string` | `""` | no |
| <a name="input_lambda_common_dir"></a> [lambda\_common\_dir](#input\_lambda\_common\_dir) | (Optional) Full dir path to the directory of shared lambda common code | `string` | `null` | no |
| <a name="input_lambda_description"></a> [lambda\_description](#input\_lambda\_description) | n/a | `string` | `""` | no |
| <a name="input_lambda_env_vars"></a> [lambda\_env\_vars](#input\_lambda\_env\_vars) | Environmental variables to expose to Lambda function | `map(string)` | n/a | yes |
| <a name="input_lambda_layers"></a> [lambda\_layers](#input\_lambda\_layers) | (Optional) List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function | `list(string)` | `null` | no |
| <a name="input_lambda_log_retention_period"></a> [lambda\_log\_retention\_period](#input\_lambda\_log\_retention\_period) | Days to retain the logs | `number` | `7` | no |
| <a name="input_lambda_role_name"></a> [lambda\_role\_name](#input\_lambda\_role\_name) | If you prefer injecting your IAM Role for the lambda function to use instead of<br>having the module create one for you, add the IAM Role name here.<br>Make sure your role's trust policy allows sts:AssumeRole from AWS<br>Service lambda.amazonaws.com. | `string` | `null` | no |
| <a name="input_lambda_source_dir"></a> [lambda\_source\_dir](#input\_lambda\_source\_dir) | (Optional) Path to find source lambda files | `string` | `""` | no |
| <a name="input_lambda_unique_function_name"></a> [lambda\_unique\_function\_name](#input\_lambda\_unique\_function\_name) | Name of the lambda .py file | `any` | n/a | yes |
| <a name="input_logs_kms_key_arn"></a> [logs\_kms\_key\_arn](#input\_logs\_kms\_key\_arn) | ARN to the KMS key which lambda should be using to decrypt and encrypt environmental variables | `any` | n/a | yes |
| <a name="input_main_lambda_file"></a> [main\_lambda\_file](#input\_main\_lambda\_file) | Name of the main lambda .py file inside the 'src' folder | `string` | `"main"` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | n/a | `number` | `128` | no |
| <a name="input_order"></a> [order](#input\_order) | Order of label components | `list(string)` | `[]` | no |
| <a name="input_package_type"></a> [package\_type](#input\_package\_type) | (Optional) Lambda deployment package type. Valid values are Zip and Image. Defaults to Zip. | `string` | `"Zip"` | no |
| <a name="input_project"></a> [project](#input\_project) | Project, which could be your organization name or abbreviation, e.g. 'cap' or 'cpb-cloud'. Might be the same as project\_id | `string` | n/a | yes |
| <a name="input_provisioned_concurrency"></a> [provisioned\_concurrency](#input\_provisioned\_concurrency) | Pre-provisions capacity. Only use when there is the requirement since it can accumulate costs rapidly. https://docs.aws.amazon.com/lambda/latest/dg/configuration-concurrency.html | `number` | `0` | no |
| <a name="input_publish"></a> [publish](#input\_publish) | Whether to publish creation/change as new Lambda Function Version | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | The region for which the lambda should have EC2 permissions for. In case you can not specify the region a wildcard will be placed | `string` | n/a | yes |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | Number of reserved concurrent executions which can not be consumed by other functions within the account. Default is unreserved (= -1) | `number` | `-1` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | (Optional) The languange/engine under which Lambda should run; see https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#SSS-CreateFunction-request-Runtime | `string` | `"python3.8"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Optional variable, use if you want to configure Lambda function to be executed inside a specific VPC | `list(string)` | `[]` | no |
| <a name="input_ssm_param_resource_arn"></a> [ssm\_param\_resource\_arn](#input\_ssm\_param\_resource\_arn) | ARN of SSM parameter to retrieve; for example, DB password | `string` | `"*"` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Environment, e.g. 'prd', 'int', 'dev', which could be the workspace name or environment | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Optional variable, use if you want to configure Lambda function to be executed inside a specific VPC | `list(string)` | `[]` | no |
| <a name="input_suppress_zip_output"></a> [suppress\_zip\_output](#input\_suppress\_zip\_output) | Whether to suppress the log output of the zip command ([...] adding: xx/xx [...] (deflated yy%)) | `bool` | `false` | no |
| <a name="input_tags_lambda"></a> [tags\_lambda](#input\_tags\_lambda) | Instance specific Tags for lambda | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The amount of time your Lambda Function has to run in seconds | `string` | `"900"` | no |
| <a name="input_use_dead_letter_config_target_arn"></a> [use\_dead\_letter\_config\_target\_arn](#input\_use\_dead\_letter\_config\_target\_arn) | n/a | `bool` | `false` | no |
| <a name="input_xray_mode"></a> [xray\_mode](#input\_xray\_mode) | (Optional) Mode defining xray tracing. PassThrough to trace the function only if X-Ray is enabled in an upstream service. Active to respect any tracing header, but if a tracing request is missing it automatically samples invocation requests | `string` | `"PassThrough"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_cloudwatch_log_group_arn"></a> [aws\_cloudwatch\_log\_group\_arn](#output\_aws\_cloudwatch\_log\_group\_arn) | n/a |
| <a name="output_aws_cloudwatch_log_group_id"></a> [aws\_cloudwatch\_log\_group\_id](#output\_aws\_cloudwatch\_log\_group\_id) | n/a |
| <a name="output_aws_cloudwatch_log_group_name"></a> [aws\_cloudwatch\_log\_group\_name](#output\_aws\_cloudwatch\_log\_group\_name) | n/a |
| <a name="output_aws_lambda_function_arn"></a> [aws\_lambda\_function\_arn](#output\_aws\_lambda\_function\_arn) | n/a |
| <a name="output_aws_lambda_function_handler"></a> [aws\_lambda\_function\_handler](#output\_aws\_lambda\_function\_handler) | n/a |
| <a name="output_aws_lambda_function_invoke_arn"></a> [aws\_lambda\_function\_invoke\_arn](#output\_aws\_lambda\_function\_invoke\_arn) | n/a |
| <a name="output_aws_lambda_function_kms_key_arn"></a> [aws\_lambda\_function\_kms\_key\_arn](#output\_aws\_lambda\_function\_kms\_key\_arn) | n/a |
| <a name="output_aws_lambda_function_name"></a> [aws\_lambda\_function\_name](#output\_aws\_lambda\_function\_name) | n/a |
| <a name="output_aws_lambda_function_role_arn"></a> [aws\_lambda\_function\_role\_arn](#output\_aws\_lambda\_function\_role\_arn) | n/a |
| <a name="output_aws_lambda_function_role_name"></a> [aws\_lambda\_function\_role\_name](#output\_aws\_lambda\_function\_role\_name) | n/a |
| <a name="output_enable"></a> [enable](#output\_enable) | n/a |
| <a name="output_lambda_zip_id"></a> [lambda\_zip\_id](#output\_lambda\_zip\_id) | n/a |
| <a name="output_source_files"></a> [source\_files](#output\_source\_files) | n/a |
<!-- END_TF_DOCS -->
