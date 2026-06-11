module "digital_twin_backend" {
  source                         = "git::ssh://git@github.com/bmadusanka/modules.git//lambda?ref=main"
  enable                         = true
  stage                          = var.stage
  project                        = var.project
  git_repository                 = ""
  package_type                   = "Zip"
  main_lambda_file               = "lambda_handler"
  lambda_base_dir                = "${abspath(path.module)}/../../lambda_source/digital_twin_backend"
  lambda_source_dir              = "${abspath(path.module)}/../../lambda_source/digital_twin_backend/build"
  region                         = var.aws_region
  additional_policy              = data.aws_iam_policy_document.digital_twin_backend.json
  lambda_unique_function_name    = "digital_twin_backend"
  runtime                        = "python3.12"
  handler                        = "handler"
  memory_size                    = 256
  timeout                        = 900
  attach_additional_policy       = true
  reserved_concurrent_executions = 10
  logs_kms_key_arn               = module.logs_bucket.aws_kms_key_arn
  lambda_description             = "Lambda function to trigger forecast model"
  artifact_bucket_name           = module.logs_bucket.s3_bucket
  lambda_env_vars = {
    BEDROCK_MODEL_ID   = var.bedrock_model_id
    CORS_ORIGINS       = "https://${resource.aws_cloudfront_distribution.this.domain_name}"
    USE_S3             = true
    S3_BUCKET          = module.data_bucket.s3_bucket
    DEFAULT_AWS_REGION = var.aws_region
  }
}

data "aws_iam_policy_document" "digital_twin_backend" {
  # checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow '*' as a statement's resource for restrictable actions"

  # 1. CloudWatch Logging Permissions
  statement {
    sid    = "AllowLambdaLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*:*",
      "arn:aws:logs:*:*:*:*:*:*",
      "arn:aws:logs:*:*:*:*"
    ]
  }

  # 2. S3 Storage Bucket Permissions
  statement {
    sid    = "AllowS3ConversationMemory"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      module.data_bucket.s3_arn,
      "${module.data_bucket.s3_arn}/*",
    ]
  }

  # 3. Secure Bedrock Inference Permissions
  statement {
    sid    = "AllowBedrockEUInference"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]
    resources = [
      "arn:aws:bedrock:*::foundation-model/amazon.nova-lite-v1:0",
      "arn:aws:bedrock:*:*:inference-profile/eu.amazon.nova-lite-v1:0",
      "arn:aws:bedrock:::foundation-model/amazon.nova-lite-v1:0"
    ]
  }
}
