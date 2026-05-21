locals {
  noncurrent_standard_ia = {
    enabled = var.noncurrent_standard_rule_enabled
    prefix  = var.noncurrent_standard_rule_prefix
    noncurrent_version_transitions = [
      {
        days          = var.noncurrent_standard_transition_days
        storage_class = "STANDARD_IA"
      }
    ]
  }
  noncurrent_onezone_ia = {
    enabled = var.noncurrent_onezone_rule_enabled,
    prefix  = var.noncurrent_onezone_rule_prefix,
    noncurrent_version_transitions = [
      {
        days          = var.noncurrent_onezone_transition_days
        storage_class = "ONEZONE_IA"
      }
    ]
  }
  noncurrent_glacier = {
    enabled = var.noncurrent_glacier_rule_enabled,
    prefix  = var.noncurrent_glacier_rule_prefix,
    noncurrent_version_transitions = [
      {
        days          = var.noncurrent_glacier_transition_days
        storage_class = "GLACIER"
      }
    ]
  }
  current_standard_ia = {
    enabled = var.current_standard_rule_enabled,
    prefix  = var.current_standard_rule_prefix,
    transitions = [
      {
        days          = var.current_standard_transition_days
        storage_class = "STANDARD_IA"
      }
    ]
  }
  current_onezone_ia = {
    enabled = var.current_onezone_rule_enabled,
    prefix  = var.current_onezone_rule_prefix,
    transitions = [
      {
        days          = var.current_onezone_transition_days
        storage_class = "ONEZONE_IA"
    }]
  }
  current_glacier = {
    enabled = var.current_glacier_rule_enabled,
    prefix  = var.current_glacier_rule_prefix,
    transitions = [
      {
        days          = var.current_glacier_transition_days
        storage_class = "GLACIER"
    }]
  }
  deep_archive = {
    enabled = var.current_deep_archive_rule_enabled,
    prefix  = var.current_deep_archive_rule_prefix,
    transitions = [
      {
        days          = var.current_deep_archive_transition_days
        storage_class = "DEEP_ARCHIVE"
      }
    ]
  }
  noncurrent_expiration = {
    enabled = var.noncurrent_expiration_rule_enabled,
    prefix  = var.noncurrent_expiration_rule_prefix,
    noncurrent_version_expirations = [
      {
        days = var.noncurrent_expiration_rule_days
      }
    ]
  }
  current_expiration = {
    enabled = var.current_expiration_rule_enabled,
    prefix  = var.current_expiration_rule_prefix,
    expirations = [
      {
        days = var.current_expiration_rule_days
      }
    ]
  }
  current_standard_ia_2 = {
    enabled = var.current_standard_rule_enabled_02,
    prefix  = var.current_standard_rule_prefix_02,
    transitions = [
      {
        days          = var.current_standard_transition_days_02
        storage_class = "STANDARD_IA"
    }]
  }
  current_glacier_2 = {
    enabled = var.current_glacier_rule_enabled_02,
    prefix  = var.current_glacier_rule_prefix_02,
    transitions = [
      {
        days          = var.current_glacier_transition_days_02
        storage_class = "GLACIER"
    }]
  }
  deep_archive_2 = {
    enabled = var.current_deep_archive_rule_enabled_02,
    prefix  = var.current_deep_archive_rule_prefix_02,
    transitions = [
      {
        days          = var.current_deep_archive_transition_days_02
        storage_class = "DEEP_ARCHIVE"
    }]
  }
  current_expiration_with_date = {
    enabled = var.current_expiration_with_date_rule_enabled,
    prefix  = var.current_expiration_with_date_rule_prefix,
    expirations_with_date = [
      {
        date = var.current_expiration_rule_date
      }
    ]
  }
  multipart_upload = {
    enabled = var.abort_incomplete_multipart_upload_enabled,
    abort_incomplete_multipart_uploads = [
      {
        days_after_initiation = var.days_after_initiation
      }
    ]

  }

  default_lifecycle_rules = [for i in [
    local.noncurrent_standard_ia,
    local.noncurrent_onezone_ia,
    local.noncurrent_glacier,
    local.current_standard_ia,
    local.current_onezone_ia,
    local.current_glacier,
    local.deep_archive,
    local.noncurrent_expiration,
    local.current_expiration,
    local.current_expiration_with_date,
    local.current_standard_ia_2,
    local.current_glacier_2,
    local.deep_archive_2,
    local.multipart_upload
  ] : i if i.enabled]
}
