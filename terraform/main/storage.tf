module "logs_bucket" {
  enable                        = true
  source                        = "git::ssh://git@github.com/bmadusanka/modules.git//s3/s3-encrypted?ref=main"
  environment                   = var.stage
  project                       = var.project
  s3_bucket_name                = "log"
  git_repository                = ""
  s3_bucket_acl                 = "log-delivery-write"
  versioning_enabled            = false
  enforce_SSL_encryption_policy = true
  force_destroy                 = true
  object_ownership              = "BucketOwnerEnforced"
  create_kms_key                = false
  kms_key_arn                   = module.project_kms_key.kms_key_arn
}

module "data_bucket" {
  enable                        = true
  source                        = "git::ssh://git@github.com/bmadusanka/modules.git//s3/s3-encrypted?ref=main"
  environment                   = var.stage
  project                       = var.project
  s3_bucket_name                = "twin-memory"
  git_repository                = ""
  s3_bucket_acl                 = "log-delivery-write"
  versioning_enabled            = false
  enforce_SSL_encryption_policy = true
  force_destroy                 = true
  object_ownership              = "BucketOwnerEnforced"
  create_kms_key                = false
  kms_key_arn                   = module.project_kms_key.kms_key_arn
}

module "frontend_bucket" {
  enable                        = true
  source                        = "git::ssh://git@github.com/bmadusanka/modules.git//s3/s3-logging-encrypted?ref=main"
  environment                   = var.stage
  project                       = var.project
  s3_bucket_name                = "twin-frontend"
  git_repository                = ""
  s3_bucket_acl                 = "log-delivery-write"
  target_bucket_id              = module.logs_bucket.s3_id
  versioning_enabled            = false
  enforce_SSL_encryption_policy = true
  force_destroy                 = true
  object_ownership              = "BucketOwnerEnforced"
  create_kms_key                = false
  use_aes256_encryption         = true
}

data "aws_iam_policy_document" "cloudfront_access" {

  statement {
    actions   = ["s3:GetObject"]
    resources = [module.frontend_bucket.s3_arn, "${module.frontend_bucket.s3_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = module.frontend_bucket.s3_id
  policy = data.aws_iam_policy_document.cloudfront_access.json
}
