data "aws_caller_identity" "current" {}
locals {
  account_id             = data.aws_caller_identity.current.account_id
  zip_flag               = var.suppress_zip_output ? "qr" : "r"
  create_lambda_iam_role = var.enable && var.lambda_role_name == null
  lambda_iam_role_name   = local.create_lambda_iam_role ? try(aws_iam_role.this[0].name) : var.lambda_role_name
}

module "lambda_label" {
  enabled = var.enable
  #checkov:skip=CKV_TF_1:we use semantic versioning, thereby git hash is **not** the preferred way
  source          = "git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label?ref=tags/0.3.0"
  stage           = var.stage
  project         = var.project
  git_repository  = var.git_repository
  name            = var.lambda_unique_function_name
  resource_group  = "lambda"
  resources       = ["role"]
  additional_tags = var.tags_lambda
  order           = var.order
}

module "lambda_policy_label" {
  enabled = var.enable
  #checkov:skip=CKV_TF_1:we use semantic versioning, thereby git hash is **not** the preferred way
  source          = "git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label?ref=tags/0.3.0"
  stage           = var.stage
  project         = var.project
  git_repository  = var.git_repository
  name            = var.lambda_unique_function_name
  resource_group  = "lambda"
  max_length      = 128
  resources       = ["base", "add", "inline"]
  additional_tags = var.tags_lambda
  order           = var.order
}

locals {
  workspace_suffix   = terraform.workspace == "default" ? "" : terraform.workspace
  default_source_dir = join("/", [var.lambda_base_dir, "src"])
  lambda_source_dir  = var.lambda_source_dir == "" ? local.default_source_dir : var.lambda_source_dir
  requirements_txt   = join("/", [var.lambda_base_dir, "requirements.txt"])
  lambda_dir_fileset = [for f in fileset(var.lambda_base_dir, "**/*.{py,txt}") : "${var.lambda_base_dir}/${f}"]
  common_dir_fileset = var.lambda_common_dir != null ? [for f in fileset(var.lambda_common_dir, "**/*.py") : "${var.lambda_common_dir}/${f}"] : []
  fileset            = concat(local.lambda_dir_fileset, local.common_dir_fileset)
  hash               = md5(join("", [for f in local.fileset : filebase64(f)]))
  hashed_zip_name    = join("-", [var.main_lambda_file, local.hash])
  s3_zip_key         = "${var.artifacts_prefix}/${module.lambda_label.id}/${local.hashed_zip_name}.zip"
  function_name      = trimsuffix(substr(module.lambda_label.id, 0, 63), "-")
}

resource "null_resource" "build_upload" {
  count = var.enable && var.package_type == "Zip" ? 1 : 0
  triggers = {
    requirements_md5   = filemd5(local.requirements_txt)
    handler_script_md5 = local.hashed_zip_name
    bucket_name        = var.artifact_bucket_name
    s3_key             = local.s3_zip_key
    external_trigger   = var.external_trigger
    # lambda tries to deploy zip file, even on configuration modifications
    environment_variables = sha256(jsonencode(var.lambda_env_vars))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    working_dir = var.lambda_base_dir
    command     = <<EOF
#!/bin/bash
set -e
bash build.sh
cd ${local.lambda_source_dir} && zip -${local.zip_flag} ../${local.hashed_zip_name}.zip ./*
EOF
  }
}

resource "aws_s3_object" "lambda_artifact_object" {
  count      = var.enable && var.package_type == "Zip" ? 1 : 0
  depends_on = [null_resource.build_upload]

  bucket = var.artifact_bucket_name
  key    = local.s3_zip_key
  source = "${local.lambda_source_dir}/../${local.hashed_zip_name}.zip"
}

resource "aws_lambda_function" "lambda" {
  #checkov:skip=CKV_AWS_50: We don't want X-Ray to be enabled by default
  #checkov:skip=CKV_AWS_116: Checks for dead-letter configuration. This is feature is usable but optional, hence this check is disabled
  #checkov:skip=CKV_AWS_272: Ensures code is signed by a trusted entity which we would need to define for all cicd users. Just generating extra costs

  count = var.enable ? 1 : 0

  package_type                   = var.package_type
  s3_bucket                      = var.package_type == "Zip" ? null_resource.build_upload[0].triggers.bucket_name : null
  s3_key                         = var.package_type == "Zip" ? coalesce(null_resource.build_upload[0].triggers.s3_key, local.s3_zip_key) : null
  image_uri                      = var.package_type == "Image" ? var.image_uri : null
  function_name                  = local.function_name
  role                           = local.create_lambda_iam_role ? aws_iam_role.this[count.index].arn : try(data.aws_iam_role.injected[count.index].arn, null)
  description                    = var.lambda_description
  handler                        = var.package_type == "Zip" ? "${var.main_lambda_file}.${var.handler}" : null
  runtime                        = var.package_type == "Zip" ? var.runtime : null
  timeout                        = var.timeout
  memory_size                    = var.memory_size
  publish                        = var.publish
  kms_key_arn                    = var.logs_kms_key_arn
  reserved_concurrent_executions = var.reserved_concurrent_executions
  layers                         = var.lambda_layers

  tracing_config {
    mode = var.xray_mode
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
  }

  environment {
    variables = var.lambda_env_vars
  }

  dynamic "image_config" {
    for_each = var.package_type == "Image" ? [1] : []

    content {
      command           = var.image_config_command
      entry_point       = var.image_config_entry_point
      working_directory = var.image_config_working_directory
    }
  }

  dynamic "dead_letter_config" {
    for_each = length(var.dead_letter_config_target_arn) > 0 ? [1] : []
    content {
      target_arn = var.dead_letter_config_target_arn
    }
  }

  ephemeral_storage {
    size = var.ephemeral_storage
  }

  depends_on = [
    null_resource.build_upload,
    aws_s3_object.lambda_artifact_object,
  ]

  tags = merge(
    module.lambda_label.tags,
    var.tags_lambda,
  )

  lifecycle {
    ignore_changes = []
  }
}
resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158: The var.logs_kms_key_arn is S3 managed thus no permissions to access it.
  #checkov:skip=CKV_AWS_338: retention days depend on module input.

  count             = var.enable ? 1 : 0
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.lambda_log_retention_period

  tags = merge(
    module.lambda_label.tags,
    var.tags_lambda,
  )
}

resource "aws_lambda_provisioned_concurrency_config" "this" {
  count                             = var.enable && var.provisioned_concurrency != 0 ? 1 : 0
  function_name                     = aws_lambda_function.lambda[0].function_name
  provisioned_concurrent_executions = var.provisioned_concurrency
  qualifier                         = aws_lambda_function.lambda[0].version

  depends_on = [aws_lambda_function.lambda]
}
