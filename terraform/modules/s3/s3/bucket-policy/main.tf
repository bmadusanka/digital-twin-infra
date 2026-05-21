
locals {
  bucket_arn = "arn:aws:s3:::${var.bucket_name}"
}

data "aws_iam_policy_document" "enforce_ssl" {
  count = var.enable && var.enforce_ssl_encryption_policy ? 1 : 0

  statement {
    sid       = "EnforceSSL"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${local.bucket_arn}/*", local.bucket_arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "allow_appflow" {
  count = var.enable && var.allow_appflow_policy ? 1 : 0

  statement {
    sid    = "AllowAppFlow"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      local.bucket_arn,
      "${local.bucket_arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["appflow.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "read_only_access_for_aws_principals_policy" {
  count = var.enable && var.read_only_access_for_aws_principals_policy != null ? 1 : 0

  statement {
    sid    = "AllowReadOnly"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${local.bucket_arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = var.read_only_access_for_aws_principals_policy
    }
  }
}

data "aws_iam_policy_document" "enforce_kms_encryption_key" {
  count = var.enable && var.enforce_kms_encryption_key_policy ? 1 : 0

  statement {
    sid       = "DenySSE-S3"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      values   = ["AES256"]
      variable = "s3:x-amz-server-side-encryption"
    }
  }

  statement {
    sid       = "RequireKMSEncryption"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test = "StringNotLikeIfExists"
      values = [
        var.kms_encryption_key_arn,
      ]
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
    }
  }

}

data "aws_iam_policy_document" "combined" {
  count = var.enable ? 1 : 0

  source_policy_documents = compact([
    var.allow_appflow_policy ? data.aws_iam_policy_document.allow_appflow[0].json : "",
    var.enforce_ssl_encryption_policy ? data.aws_iam_policy_document.enforce_ssl[0].json : "",
    var.read_only_access_for_aws_principals_policy != null ? data.aws_iam_policy_document.read_only_access_for_aws_principals_policy[0].json : "",
    var.policy != null ? var.policy : "",
    var.enforce_kms_encryption_key_policy ? data.aws_iam_policy_document.enforce_kms_encryption_key[0].json : "",
  ])
}

resource "aws_s3_bucket_policy" "this" {
  count = var.enable ? 1 : 0

  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.combined[count.index].json
}
