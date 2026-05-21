variable "environment" {
  description = "Environment of the Stack"
  type        = string
}

variable "project" {
  description = "Specify to which project this resource belongs"
  default     = ""
  type        = string
}

variable "projectID" {
  description = "Specify to which project this resource belongs, tag is used for cost allocation"
  default     = ""
  type        = string
}


variable "kst" {
  description = "Kostenstelle, Cost Center number"
  default     = "Not Set"
  type        = string
}

variable "wa_number" {
  description = "WA Number of the project"
  default     = "Not Set"
  type        = string
}

variable "git_repository" {
  description = "Repository where the S3 bucket is deployed from."
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the bucket"
  type        = string
}

variable "s3_bucket_acl" {
  description = "Private or Public"
  default     = "private"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 10 days."
  default     = 10
  type        = number
}

variable "force_destroy" {
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Specifies whether versioning is enabled for the S3 bucket."
  default     = false
  type        = bool
}

variable "enforce_SSL_encryption_policy" {
  description = "Attach Bucket policy to force SSL encryption"
  type        = bool
  default     = false
}

variable "use_aes256_encryption" {
  description = "Boolean value to tell if the AES256 encryption should be used"
  default     = false
  type        = bool
}

variable "current_expiration_with_date_rule_enabled" {
  description = "Specifies whether the expiration lifecycle with date is enabled on the bucket."
  default     = false
  type        = bool
}

variable "current_expiration_with_date_rule_prefix" {
  description = "Specifies prefix for expiration lifecycle with date rule."
  default     = ""
  type        = string

}

variable "current_expiration_rule_date" {
  description = "Specific date after which to expunge the objects"
  default     = ""
  type        = string
}


variable "tags_s3" {
  description = "Instance specific Tags for s3 bucket"
  type        = map(string)
  default     = {}
}

variable "tags_kms" {
  description = "Instance specific Tags for S3 kms key"
  type        = map(string)
  default     = {}
}

variable "enable_key_rotation" {
  description = "Specifies whether key rotation is enabled."
  default     = true
  type        = bool
}

variable "bucket_grants" {
  description = "List of maps containing with each list element containing a map with type, id and permissions/uri keys: [{'type':'', 'id':'', 'permissions':''},]. When ID is set URI needs to be null and vice versa. You can't set both"
  type = list(object({
    id          = string
    type        = string
    permissions = list(string)
    uri         = string
  }))
  default = []
}

variable "enable" {
  description = "Set to false to prevent the module from creating any resources."
  default     = true
  type        = bool
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket."
  default     = true
  type        = bool
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  default     = true
  type        = bool
}

variable "lambda_functions" {
  description = "map of <lambda_function_arn>, OPTIONAL: list of <events> (defaults to [s3:ObjectCreated:*]) for which to send notifications, [filter_prefix] and [filter_suffix]."
  default     = {}
  type = map(object({
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string)
    filter_suffix       = optional(string)
  }))
}
variable "queues" {
  description = "map of <queue_arn>, OPTIONAL: list of <events> (defaults to [s3:ObjectCreated:*]) for which to send notifications, [filter_prefix] and [filter_suffix]."
  default     = {}
  type = map(object({
    queue_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
}
variable "topics" {
  description = "map of <topic_arn>, OPTIONAL: list of <events> (defaults to [s3:ObjectCreated:*]) for which to send notifications, [filter_prefix] and [filter_suffix]."
  default     = {}
  type = map(object({
    topic_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
}

variable "cors_rule" {
  description = "Specifies the allowed headers, methods, origins and exposed headers when using CORS on this bucket"
  default     = []
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
}

variable "bucket_key_enabled" {
  description = "(Optional) Whether or not to use Amazon S3 Bucket Keys for SSE-KMS."
  type        = bool
  default     = false
}

variable "kms_policy_to_attach" {
  description = "(Optional) KMS policy to attach to. A valid policy JSON document. By default, If a key policy is not specified, AWS gives the KMS key a default key policy that gives all principals in the owning account unlimited access to all KMS operations for the key."
  type        = string
  default     = ""
}

variable "object_ownership" {
  description = "S3 Bucket Ownership Controls"
  default     = "BucketOwnerEnforced"
  type        = string
}

#### Dynamically created Lifecycle rules ####
variable "lifecycle_rules" {
  description = "List of Lifecycle rules applied to objects in the bucket"
  default     = []
  # Note! Because of the object's "optional" attribute, Terraform required_version = ">= 1.3.0")
  type = list(object({
    enabled = optional(bool)
    prefix  = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expirations = optional(list(object({
      days = optional(number)
      date = optional(string) # Must be in RFC3339 time format, e.g.: "2026-12-09T00:00:00+00:00"
    })), [])
    noncurrent_version_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_expirations = optional(list(object({
      days = number
    })), [])
    abort_incomplete_multipart_uploads = optional(list(object({
      days_after_initiation = number
    })), [])
  }))

  /*  type        = list(object({
    enabled = string
    prefix = string
    expirations = list(object({
      days = number
    }))
    noncurrent_version_expirations = list(object({
      days = number
    }))
    transitions = list(object({
      days = number
      storage_class = string
    }))
    noncurrent_version_transitions = list(object({
      days = number
      storage_class = string
    }))
  }))*/
}

variable "allow_appflow_policy" {
  description = "Whether or not to add a statement to the bucket policy allowing appflow to list the bucket and get object."
  default     = false
  type        = bool
}

variable "attach_custom_bucket_policy" {
  description = "Whether or not to attach a custom bucket policy."
  type        = bool
  default     = false
}

variable "policy" {
  description = "A json policy document"
  type        = string
  default     = ""
}

# Object lock configuration

variable "enable_object_lock" {
  description = "Needs to be enabled and configured on bucket creation. Whether or not to enable the object lock"
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Mode to set for object lock. Valid values are 'GOVERNANCE' and 'COMPLIANCE'. Default is 'COMPLIANCE'"
  type        = string
  default     = "COMPLIANCE"
}

variable "object_lock_retention_days" {
  description = "(Optional, Required if object_lock_retention_years is not specified) The number of days that you want to specify for the default retention period."
  type        = number
  default     = -1
}

variable "object_lock_retention_years" {
  description = "(Optional, Required if object_lock_retention_days is not specified) The number of years that you want to specify for the default retention period"
  type        = number
  default     = -1
}

########################
# KMS key variables
########################

variable "create_kms_key" {
  description = "Whether to create a KMS key or not. IMPORTANT: If the module has been used before, set this variable to 'true' to not loose the previously created KMS key and the encrypted data. If the module is used for the first time set this variable to `false` and manage the KMS key outside of this module and provide the KMS key ARN"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The KMS key ARN to use for the encrypted resources within this module"
  type        = string
  default     = ""
}

# STANDARD_IA #
variable "current_standard_rule_enabled" {
  description = "Specifies whether the standard_ia lifecycle rule is enabled."
  default     = false
  type        = bool
}

variable "current_standard_rule_prefix" {
  description = "Specifies prefix for the standard lifecycle rule."
  default     = ""
  type        = string
}

variable "current_standard_transition_days" {
  description = "Specifies transition days for the standard lifecycle rule."
  default     = 30
  type        = number
}

variable "current_standard_rule_enabled_02" {
  description = "Specifies whether the second standard lifecycle rule is enabled."
  default     = false
  type        = bool
}

variable "current_standard_rule_prefix_02" {
  description = "Specifies prefix for the second standard lifecycle rule."
  default     = ""
  type        = string
}

variable "current_standard_transition_days_02" {
  description = "Specifies transition days for the second standard lifecycle rule."
  default     = 30
  type        = number
}

#### Transition lifecycle rule for  noncurrent versions ####

# STANDARD_IA #
variable "noncurrent_standard_rule_enabled" {
  description = "Specifies whether the standard lifecycle rule is enabled for noncurrent versions."
  default     = false
  type        = bool
}

variable "noncurrent_standard_rule_prefix" {
  description = "Specifies prefix for the standard lifecycle rule for noncurrent versions."
  default     = ""
  type        = string
}

variable "noncurrent_standard_transition_days" {
  description = "Specifies transition days for the standard lifecycle rule for noncurrent versions."
  default     = 30
  type        = number
}

# ONEZONE_IA #
variable "current_onezone_rule_enabled" {
  description = "Specifies whether the onezone_ia lifecycle rule is enabled."
  default     = false
  type        = bool
}

variable "current_onezone_rule_prefix" {
  description = "Specifies prefix for the onezone_ia lifecycle rule."
  default     = ""
  type        = string
}

variable "current_onezone_transition_days" {
  description = "Specifies transition days for onezone_ia lifecycle rule."
  default     = 30
  type        = number
}

# ONEZONE_IA #
variable "noncurrent_onezone_rule_enabled" {
  description = "Specifies whether the onezone_ia lifecycle rule is enabled for noncurrent versions."
  default     = false
  type        = bool
}

variable "noncurrent_onezone_rule_prefix" {
  description = "Specifies prefix for the onezone_ia lifecycle rule for noncurrent versions."
  default     = ""
  type        = string
}

variable "noncurrent_onezone_transition_days" {
  description = "Specifies transition days for the onezone_ia lifecycle rule for noncurrent versions."
  default     = 30
  type        = number
}

# GLACIER #
variable "noncurrent_glacier_rule_enabled" {
  description = "Specifies whether the glacier lifecycle rule is enabled for noncurrent versions."
  default     = false
  type        = bool
}

variable "noncurrent_glacier_rule_prefix" {
  description = "Specifies prefix for the glacier lifecycle rule for noncurrent versions."
  default     = ""
  type        = string
}

variable "noncurrent_glacier_transition_days" {
  description = "Specifies transition days for the glacier lifecycle rule for noncurrent versions."
  default     = 30
  type        = number
}

# GLACIER #
variable "current_glacier_rule_enabled" {
  description = "Specifies whether the glacier lifecycle rule is enabled."
  default     = false
  type        = bool
}

variable "current_glacier_rule_prefix" {
  description = "Specifies prefix for the glacier lifecycle rule."
  default     = ""
  type        = string
}

variable "current_glacier_transition_days" {
  description = "Specifies transition days for glacier lifecycle rule."
  default     = 30
  type        = number
}

# 2nd GLACIER #
variable "current_glacier_rule_enabled_02" {
  description = "Specifies whether the second glacier lifecycle rule is enabled."
  default     = false
  type        = bool
}

variable "current_glacier_rule_prefix_02" {
  description = "Specifies prefix for second glacier lifecycle rule."
  default     = ""
  type        = string
}

variable "current_glacier_transition_days_02" {
  description = "Specifies transition days for second glacier lifecycle rule."
  default     = 30
  type        = number
}

# DEEP ARCHIVE #
variable "current_deep_archive_rule_enabled" {
  description = "Specifies whether the deep archive rule is enabled."
  default     = false
  type        = bool
}

variable "current_deep_archive_rule_prefix" {
  description = "Specifies prefix for deep archive lifecycle rule."
  default     = ""
  type        = string
}

variable "current_deep_archive_transition_days" {
  description = "Specifies transition days for deep archive lifecycle rule."
  default     = 150
  type        = number
}

# 2nd DEEP ARCHIVE #
variable "current_deep_archive_rule_enabled_02" {
  description = "Specifies whether the second deep archive rule is enabled."
  default     = false
  type        = bool
}

variable "current_deep_archive_rule_prefix_02" {
  description = "Specifies prefix for second deep archive lifecycle rule."
  default     = ""
  type        = string
}

variable "current_deep_archive_transition_days_02" {
  description = "Specifies transition days for second deep archive lifecycle rule."
  default     = 150
  type        = number
}

#### Expiration lifecycle rule for noncurrent versions ####
variable "noncurrent_expiration_rule_enabled" {
  description = "Specifies whether expiration lifecycle rule for noncurrent versions is enabled."
  default     = false
  type        = bool
}

variable "noncurrent_expiration_rule_prefix" {
  description = "Specify prefix for non-current expiration rule."
  default     = ""
  type        = string
}

variable "noncurrent_expiration_rule_days" {
  description = "Number of days after which to expunge the objects"
  default     = "30"
  type        = string
}

#### Expiration lifecycle rule with date for current versions ####

variable "current_expiration_rule_enabled" {
  description = "Specifies whether expiration lifecycle rule for current versions is enabled."
  default     = false
  type        = bool
}

variable "current_expiration_rule_prefix" {
  description = "Specify prefix for current expiration rule."
  default     = ""
  type        = string
}

variable "current_expiration_rule_days" {
  description = "Number of days after which to expunge the objects"
  default     = "30"
  type        = string
}

#### Expiration lifecycle rule for old incomplete multi-part uploads ####

# Old incomplete multi-part uploads
variable "abort_incomplete_multipart_upload_enabled" {
  description = "Delete old incomplete multi-part uploads."
  default     = false
  type        = bool
}

variable "days_after_initiation" {
  description = "Number of days after which Amazon S3 aborts an incomplete multipart upload."
  default     = 7
  type        = number
}

# Enable Bucket as access logs target

variable "access_logs_target_configs" {
  description = "Whether or not to enable bucket as access logs target. S3 object lock must be disabled for access logs target buckets."
  type = object({
    enabled                   = optional(bool, false)
    source_bucket_arns        = optional(list(string), [])
    source_bucket_account_ids = optional(list(string), [])
  })
  default = {}
}
