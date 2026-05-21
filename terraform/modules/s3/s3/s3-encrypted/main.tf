data "aws_canonical_user_id" "current" {}
data "aws_caller_identity" "current" {}

locals {
  kms_key_alias  = module.labels.resource["kms-key"].id
  kms_alias_name = "alias/${local.kms_key_alias}"
  kms_key_arn    = var.create_kms_key && var.enable ? try(aws_kms_key.this[0].arn, "") : var.kms_key_arn

  lifecycle_rules  = concat(var.lifecycle_rules, local.default_lifecycle_rules)
  attach_s3_policy = var.allow_appflow_policy || var.enforce_SSL_encryption_policy || var.attach_custom_bucket_policy

  access_logs_source_account_ids = coalescelist(var.access_logs_target_configs.source_bucket_account_ids, [data.aws_caller_identity.current.account_id])
}

module "labels" {
  source = "git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label?ref=tags/0.3.0"

  max_length      = 63
  project         = var.project
  project_id      = var.projectID == "" ? var.project : var.projectID
  stage           = var.environment
  kst             = var.kst
  wa_number       = var.wa_number
  name            = var.s3_bucket_name
  resources       = ["kms-key"]
  additional_tags = var.tags_s3
  git_repository  = var.git_repository
}

module "labels_lifecycle_rules" {
  source          = "git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label?ref=tags/0.3.0"
  max_length      = 96
  project         = var.project
  project_id      = var.projectID == "" ? var.project : var.projectID
  stage           = var.environment
  kst             = var.kst
  wa_number       = var.wa_number
  name            = var.s3_bucket_name
  resource_group  = "lifecycle-rule"
  resources       = range(length(local.lifecycle_rules))
  additional_tags = var.tags_s3
  git_repository  = var.git_repository
}

resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_18:  This module is typically used for log buckets. Hence the logging for these buckets is
  #                          disabled to avoid log loops
  #checkov:skip=CKV_AWS_21:  We don't want versioning to be enabled by default for every bucket
  #checkov:skip=CKV_AWS_144: We don't want cross-region-replication to be enabled by default
  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
  #checkov:skip=CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
  #checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  #checkov:skip=CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"

  count = var.enable ? 1 : 0

  bucket              = module.labels.id
  force_destroy       = var.force_destroy
  object_lock_enabled = var.enable_object_lock

  lifecycle {
    ignore_changes = [
      lifecycle_rule,
      server_side_encryption_configuration,
      logging,
      acl
    ]
  }

  tags = merge(
    var.tags_s3,
    module.labels.tags
  )
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.enable && contains([
  var.block_public_acls, var.block_public_policy, var.ignore_public_acls, var.restrict_public_buckets], true) ? 1 : 0
  bucket = aws_s3_bucket.this[count.index].id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count      = var.enable ? 1 : 0
  bucket     = aws_s3_bucket.this[count.index].id
  depends_on = [aws_s3_bucket_public_access_block.this]

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_kms_key" "this" {
  count                   = !var.use_aes256_encryption && var.enable && var.create_kms_key ? 1 : 0
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = var.deletion_window_in_days
  is_enabled              = true
  enable_key_rotation     = var.enable_key_rotation
  policy                  = length(var.kms_policy_to_attach) > 0 ? var.kms_policy_to_attach : null
  tags = merge(
    var.tags_kms,
    module.labels.resource["kms-key"].tags
  )
}

resource "aws_kms_alias" "this" {
  count = !var.use_aes256_encryption && var.enable && var.create_kms_key ? 1 : 0

  name          = local.kms_alias_name
  target_key_id = aws_kms_key.this[count.index].arn
}

data "aws_iam_policy_document" "enforce_ssl" {
  count = var.enable && var.enforce_SSL_encryption_policy ? 1 : 0

  statement {
    sid       = "EnforceSSL"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.this[count.index].arn}/*", aws_s3_bucket.this[count.index].arn]

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
      aws_s3_bucket.this[count.index].arn,
      "${aws_s3_bucket.this[count.index].arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["appflow.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allow_access_logs_server" {
  count = var.enable && var.access_logs_target_configs.enabled ? 1 : 0

  statement {
    sid    = "S3ServerAccessLogsPolicy"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.this[count.index].arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = local.access_logs_source_account_ids
    }

    dynamic "condition" {
      for_each = (
        length(var.access_logs_target_configs.source_bucket_arns) > 0 ? toset([1]) : toset([])
      )
      content {
        test     = "ArnLike"
        variable = "aws:SourceARN"
        values   = var.access_logs_target_configs.source_bucket_arns
      }
    }
  }
}

data "aws_iam_policy_document" "combined" {
  count = var.enable && local.attach_s3_policy ? 1 : 0

  source_policy_documents = compact([
    var.allow_appflow_policy ? data.aws_iam_policy_document.allow_appflow[0].json : "",
    var.enforce_SSL_encryption_policy ? data.aws_iam_policy_document.enforce_ssl[0].json : "",
    var.access_logs_target_configs.enabled ? data.aws_iam_policy_document.allow_access_logs_server[0].json : "",
    var.attach_custom_bucket_policy ? var.policy : "",
  ])
}

resource "aws_s3_bucket_policy" "this" {
  count = var.enable && local.attach_s3_policy ? 1 : 0

  bucket     = aws_s3_bucket.this[count.index].id
  policy     = data.aws_iam_policy_document.combined[count.index].json
  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_notification" "triggers" {
  count = var.enable && length(merge(var.lambda_functions, var.queues, var.topics)) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[count.index].bucket

  dynamic "lambda_function" {
    for_each = var.lambda_functions
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lookup(lambda_function.value, "events", ["s3:ObjectCreated:*"])
      // See https://aws.amazon.com/premiumsupport/knowledge-center/lambda-configure-s3-event-notification/
      filter_prefix = contains(keys(lambda_function.value), "filter_prefix") ? "${urlencode(lambda_function.value.filter_prefix)}/" : ""
      filter_suffix = contains(keys(lambda_function.value), "filter_suffix") ? lambda_function.value.filter_suffix : ""
    }
  }
  dynamic "queue" {
    for_each = var.queues
    content {
      queue_arn = queue.value.queue_arn
      events    = lookup(queue.value, "events", ["s3:ObjectCreated:*"])
      // See https://aws.amazon.com/premiumsupport/knowledge-center/lambda-configure-s3-event-notification/
      filter_prefix = contains(keys(queue.value), "filter_prefix") ? "${urlencode(queue.value.filter_prefix)}/" : ""
      filter_suffix = contains(keys(queue.value), "filter_suffix") ? queue.value.filter_suffix : ""
    }
  }
  dynamic "topic" {
    for_each = var.topics
    content {
      topic_arn = topic.value.topic_arn
      events    = lookup(topic.value, "events", ["s3:ObjectCreated:*"])
      // See https://aws.amazon.com/premiumsupport/knowledge-center/lambda-configure-s3-event-notification/
      filter_prefix = contains(keys(topic.value), "filter_prefix") ? "${topic.value.filter_prefix}/" : ""
      filter_suffix = contains(keys(topic.value), "filter_suffix") ? topic.value.filter_suffix : ""
    }
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  count = var.enable && length(var.bucket_grants) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[count.index].id
  acl    = length(var.bucket_grants) != 0 || var.object_ownership == "BucketOwnerEnforced" ? null : var.s3_bucket_acl

  dynamic "access_control_policy" {
    for_each = var.bucket_grants
    content {
      grant {
        grantee {
          id   = access_control_policy.value.id
          uri  = access_control_policy.value.uri
          type = access_control_policy.value.type
        }
        permission = access_control_policy.value.permissions
      }

      owner {
        id = data.aws_canonical_user_id.current.id
      }
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "cors_config" {
  count  = var.enable && length(var.cors_rule) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this[count.index].bucket

  dynamic "cors_rule" {
    for_each = var.cors_rule
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_configuration" {
  #checkov:skip=CKV_AWS_300: https://github.com/bridgecrewio/checkov/pull/4750
  count  = var.enable && length(local.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this[count.index].id

  depends_on = [aws_s3_bucket_versioning.bucket_version]

  dynamic "rule" {
    for_each = local.lifecycle_rules
    content {
      id = module.labels_lifecycle_rules.resource[rule.key]["id"]
      filter {
        prefix = lookup(rule.value, "prefix", "")
      }

      # CURRENT VERSIONS RULES
      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expirations", [])
        content {
          days = lookup(expiration.value, "days", null)
          date = lookup(expiration.value, "date", null)
        }
      }

      # NON-CURRENT VERSIONS RULES
      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transitions", [])
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expirations", [])
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
      status = rule.value.enabled == true ? "Enabled" : "Disabled"
    }
  }
}

resource "aws_s3_bucket_versioning" "bucket_version" {
  count = var.enable && var.versioning_enabled ? 1 : 0

  bucket = aws_s3_bucket.this[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_configuration" {
  # checkov:skip=CKV2_AWS_67:KMS Key management has been descoped/deprecated from this module as stated by description in variables.tf
  count = var.enable ? 1 : 0

  bucket = aws_s3_bucket.this[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.use_aes256_encryption ? "AES256" : "aws:kms"
      kms_master_key_id = local.kms_key_arn
    }
    bucket_key_enabled = var.use_aes256_encryption ? null : var.bucket_key_enabled
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.enable && var.enable_object_lock && !var.access_logs_target_configs.enabled ? 1 : 0

  bucket = aws_s3_bucket.this[count.index].bucket

  dynamic "rule" {
    for_each = var.object_lock_retention_days != -1 ? [1] : []
    content {
      default_retention {
        mode = var.object_lock_mode
        days = var.object_lock_retention_days
      }
    }
  }

  dynamic "rule" {
    for_each = var.object_lock_retention_years != -1 ? [1] : []
    content {
      default_retention {
        mode  = var.object_lock_mode
        years = var.object_lock_retention_years
      }
    }
  }
}
