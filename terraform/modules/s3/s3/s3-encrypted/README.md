`s3-encrypted`
===

## Bucket Policies:

If one of the variables that enable a policy is set (`policy`, `enforce_SSL_encryption_policy`, `allow_appflow_policy`),
the module creates a policy and attaches it to the bucket.
This means that **no** other policy can be attached outside this module.
If a policy is attached via `aws_s3_bucket_policy` the behavior is unpredictable, i.e. it's random which policy will be used,
and it can change from deployment to deployment.

If there is the need of a more custom policy, all policy variables (`policy`, `enforce_SSL_encryption_policy`, `allow_appflow_policy`)
**must not** be set and the full policy has to be created and attached outside the module.

**NOTE:** When using this module for the first time, **inject the KMS key** instead of making the module create one. The
 feature to create a KMS key is just still enabled to ensure backwards compatibility.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.57 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.57 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_labels"></a> [labels](#module\_labels) | git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label | tags/0.3.0 |
| <a name="module_labels_lifecycle_rules"></a> [labels\_lifecycle\_rules](#module\_labels\_lifecycle\_rules) | git::ssh://cap-tf-module-label/vwdfive/cap-tf-module-label | tags/0.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.bucket_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_cors_configuration.cors_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.lifecycle_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_notification.triggers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_object_lock_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.encryption_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.bucket_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_iam_policy_document.allow_access_logs_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.allow_appflow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.combined](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.enforce_ssl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_abort_incomplete_multipart_upload_enabled"></a> [abort\_incomplete\_multipart\_upload\_enabled](#input\_abort\_incomplete\_multipart\_upload\_enabled) | Delete old incomplete multi-part uploads. | `bool` | `false` | no |
| <a name="input_access_logs_target_configs"></a> [access\_logs\_target\_configs](#input\_access\_logs\_target\_configs) | Whether or not to enable bucket as access logs target. S3 object lock must be disabled for access logs target buckets. | <pre>object({<br>    enabled                   = optional(bool, false)<br>    source_bucket_arns        = optional(list(string), [])<br>    source_bucket_account_ids = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_allow_appflow_policy"></a> [allow\_appflow\_policy](#input\_allow\_appflow\_policy) | Whether or not to add a statement to the bucket policy allowing appflow to list the bucket and get object. | `bool` | `false` | no |
| <a name="input_attach_custom_bucket_policy"></a> [attach\_custom\_bucket\_policy](#input\_attach\_custom\_bucket\_policy) | Whether or not to attach a custom bucket policy. | `bool` | `false` | no |
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | Whether Amazon S3 should block public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | Whether Amazon S3 should block public bucket policies for this bucket. | `bool` | `true` | no |
| <a name="input_bucket_grants"></a> [bucket\_grants](#input\_bucket\_grants) | List of maps containing with each list element containing a map with type, id and permissions/uri keys: [{'type':'', 'id':'', 'permissions':''},]. When ID is set URI needs to be null and vice versa. You can't set both | <pre>list(object({<br>    id          = string<br>    type        = string<br>    permissions = list(string)<br>    uri         = string<br>  }))</pre> | `[]` | no |
| <a name="input_bucket_key_enabled"></a> [bucket\_key\_enabled](#input\_bucket\_key\_enabled) | (Optional) Whether or not to use Amazon S3 Bucket Keys for SSE-KMS. | `bool` | `false` | no |
| <a name="input_cors_rule"></a> [cors\_rule](#input\_cors\_rule) | Specifies the allowed headers, methods, origins and exposed headers when using CORS on this bucket | <pre>list(object({<br>    allowed_headers = list(string)<br>    allowed_methods = list(string)<br>    allowed_origins = list(string)<br>    expose_headers  = list(string)<br>    max_age_seconds = number<br>  }))</pre> | `[]` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Whether to create a KMS key or not. IMPORTANT: If the module has been used before, set this variable to 'true' to not loose the previously created KMS key and the encrypted data. If the module is used for the first time set this variable to `false` and manage the KMS key outside of this module and provide the KMS key ARN | `bool` | `true` | no |
| <a name="input_current_deep_archive_rule_enabled"></a> [current\_deep\_archive\_rule\_enabled](#input\_current\_deep\_archive\_rule\_enabled) | Specifies whether the deep archive rule is enabled. | `bool` | `false` | no |
| <a name="input_current_deep_archive_rule_enabled_02"></a> [current\_deep\_archive\_rule\_enabled\_02](#input\_current\_deep\_archive\_rule\_enabled\_02) | Specifies whether the second deep archive rule is enabled. | `bool` | `false` | no |
| <a name="input_current_deep_archive_rule_prefix"></a> [current\_deep\_archive\_rule\_prefix](#input\_current\_deep\_archive\_rule\_prefix) | Specifies prefix for deep archive lifecycle rule. | `string` | `""` | no |
| <a name="input_current_deep_archive_rule_prefix_02"></a> [current\_deep\_archive\_rule\_prefix\_02](#input\_current\_deep\_archive\_rule\_prefix\_02) | Specifies prefix for second deep archive lifecycle rule. | `string` | `""` | no |
| <a name="input_current_deep_archive_transition_days"></a> [current\_deep\_archive\_transition\_days](#input\_current\_deep\_archive\_transition\_days) | Specifies transition days for deep archive lifecycle rule. | `number` | `150` | no |
| <a name="input_current_deep_archive_transition_days_02"></a> [current\_deep\_archive\_transition\_days\_02](#input\_current\_deep\_archive\_transition\_days\_02) | Specifies transition days for second deep archive lifecycle rule. | `number` | `150` | no |
| <a name="input_current_expiration_rule_date"></a> [current\_expiration\_rule\_date](#input\_current\_expiration\_rule\_date) | Specific date after which to expunge the objects | `string` | `""` | no |
| <a name="input_current_expiration_rule_days"></a> [current\_expiration\_rule\_days](#input\_current\_expiration\_rule\_days) | Number of days after which to expunge the objects | `string` | `"30"` | no |
| <a name="input_current_expiration_rule_enabled"></a> [current\_expiration\_rule\_enabled](#input\_current\_expiration\_rule\_enabled) | Specifies whether expiration lifecycle rule for current versions is enabled. | `bool` | `false` | no |
| <a name="input_current_expiration_rule_prefix"></a> [current\_expiration\_rule\_prefix](#input\_current\_expiration\_rule\_prefix) | Specify prefix for current expiration rule. | `string` | `""` | no |
| <a name="input_current_expiration_with_date_rule_enabled"></a> [current\_expiration\_with\_date\_rule\_enabled](#input\_current\_expiration\_with\_date\_rule\_enabled) | Specifies whether the expiration lifecycle with date is enabled on the bucket. | `bool` | `false` | no |
| <a name="input_current_expiration_with_date_rule_prefix"></a> [current\_expiration\_with\_date\_rule\_prefix](#input\_current\_expiration\_with\_date\_rule\_prefix) | Specifies prefix for expiration lifecycle with date rule. | `string` | `""` | no |
| <a name="input_current_glacier_rule_enabled"></a> [current\_glacier\_rule\_enabled](#input\_current\_glacier\_rule\_enabled) | Specifies whether the glacier lifecycle rule is enabled. | `bool` | `false` | no |
| <a name="input_current_glacier_rule_enabled_02"></a> [current\_glacier\_rule\_enabled\_02](#input\_current\_glacier\_rule\_enabled\_02) | Specifies whether the second glacier lifecycle rule is enabled. | `bool` | `false` | no |
| <a name="input_current_glacier_rule_prefix"></a> [current\_glacier\_rule\_prefix](#input\_current\_glacier\_rule\_prefix) | Specifies prefix for the glacier lifecycle rule. | `string` | `""` | no |
| <a name="input_current_glacier_rule_prefix_02"></a> [current\_glacier\_rule\_prefix\_02](#input\_current\_glacier\_rule\_prefix\_02) | Specifies prefix for second glacier lifecycle rule. | `string` | `""` | no |
| <a name="input_current_glacier_transition_days"></a> [current\_glacier\_transition\_days](#input\_current\_glacier\_transition\_days) | Specifies transition days for glacier lifecycle rule. | `number` | `30` | no |
| <a name="input_current_glacier_transition_days_02"></a> [current\_glacier\_transition\_days\_02](#input\_current\_glacier\_transition\_days\_02) | Specifies transition days for second glacier lifecycle rule. | `number` | `30` | no |
| <a name="input_current_onezone_rule_enabled"></a> [current\_onezone\_rule\_enabled](#input\_current\_onezone\_rule\_enabled) | Specifies whether the onezone\_ia lifecycle rule is enabled. | `bool` | `false` | no |
| <a name="input_current_onezone_rule_prefix"></a> [current\_onezone\_rule\_prefix](#input\_current\_onezone\_rule\_prefix) | Specifies prefix for the onezone\_ia lifecycle rule. | `string` | `""` | no |
| <a name="input_current_onezone_transition_days"></a> [current\_onezone\_transition\_days](#input\_current\_onezone\_transition\_days) | Specifies transition days for onezone\_ia lifecycle rule. | `number` | `30` | no |
| <a name="input_current_standard_rule_enabled"></a> [current\_standard\_rule\_enabled](#input\_current\_standard\_rule\_enabled) | Specifies whether the standard\_ia lifecycle rule is enabled. | `bool` | `false` | no |
| <a name="input_current_standard_rule_enabled_02"></a> [current\_standard\_rule\_enabled\_02](#input\_current\_standard\_rule\_enabled\_02) | Specifies whether the second standard lifecycle rule is enabled. | `bool` | `false` | no |
| <a name="input_current_standard_rule_prefix"></a> [current\_standard\_rule\_prefix](#input\_current\_standard\_rule\_prefix) | Specifies prefix for the standard lifecycle rule. | `string` | `""` | no |
| <a name="input_current_standard_rule_prefix_02"></a> [current\_standard\_rule\_prefix\_02](#input\_current\_standard\_rule\_prefix\_02) | Specifies prefix for the second standard lifecycle rule. | `string` | `""` | no |
| <a name="input_current_standard_transition_days"></a> [current\_standard\_transition\_days](#input\_current\_standard\_transition\_days) | Specifies transition days for the standard lifecycle rule. | `number` | `30` | no |
| <a name="input_current_standard_transition_days_02"></a> [current\_standard\_transition\_days\_02](#input\_current\_standard\_transition\_days\_02) | Specifies transition days for the second standard lifecycle rule. | `number` | `30` | no |
| <a name="input_days_after_initiation"></a> [days\_after\_initiation](#input\_days\_after\_initiation) | Number of days after which Amazon S3 aborts an incomplete multipart upload. | `number` | `7` | no |
| <a name="input_deletion_window_in_days"></a> [deletion\_window\_in\_days](#input\_deletion\_window\_in\_days) | Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 10 days. | `number` | `10` | no |
| <a name="input_enable"></a> [enable](#input\_enable) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_enable_key_rotation"></a> [enable\_key\_rotation](#input\_enable\_key\_rotation) | Specifies whether key rotation is enabled. | `bool` | `true` | no |
| <a name="input_enable_object_lock"></a> [enable\_object\_lock](#input\_enable\_object\_lock) | Needs to be enabled and configured on bucket creation. Whether or not to enable the object lock | `bool` | `false` | no |
| <a name="input_enforce_SSL_encryption_policy"></a> [enforce\_SSL\_encryption\_policy](#input\_enforce\_SSL\_encryption\_policy) | Attach Bucket policy to force SSL encryption | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment of the Stack | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_git_repository"></a> [git\_repository](#input\_git\_repository) | Repository where the S3 bucket is deployed from. | `string` | n/a | yes |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | Whether Amazon S3 should ignore public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The KMS key ARN to use for the encrypted resources within this module | `string` | `""` | no |
| <a name="input_kms_policy_to_attach"></a> [kms\_policy\_to\_attach](#input\_kms\_policy\_to\_attach) | (Optional) KMS policy to attach to. A valid policy JSON document. By default, If a key policy is not specified, AWS gives the KMS key a default key policy that gives all principals in the owning account unlimited access to all KMS operations for the key. | `string` | `""` | no |
| <a name="input_kst"></a> [kst](#input\_kst) | Kostenstelle, Cost Center number | `string` | `"Not Set"` | no |
| <a name="input_lambda_functions"></a> [lambda\_functions](#input\_lambda\_functions) | map of <lambda\_function\_arn>, OPTIONAL: list of <events> (defaults to [s3:ObjectCreated:*]) for which to send notifications, [filter\_prefix] and [filter\_suffix]. | <pre>map(object({<br>    lambda_function_arn = string<br>    events              = list(string)<br>    filter_prefix       = optional(string)<br>    filter_suffix       = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of Lifecycle rules applied to objects in the bucket | <pre>list(object({<br>    enabled = optional(bool)<br>    prefix  = optional(string)<br>    transitions = optional(list(object({<br>      days          = number<br>      storage_class = string<br>    })), [])<br>    expirations = optional(list(object({<br>      days = optional(number)<br>      date = optional(string) # Must be in RFC3339 time format, e.g.: "2026-12-09T00:00:00+00:00"<br>    })), [])<br>    noncurrent_version_transitions = optional(list(object({<br>      days          = number<br>      storage_class = string<br>    })), [])<br>    noncurrent_version_expirations = optional(list(object({<br>      days = number<br>    })), [])<br>    abort_incomplete_multipart_uploads = optional(list(object({<br>      days_after_initiation = number<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_noncurrent_expiration_rule_days"></a> [noncurrent\_expiration\_rule\_days](#input\_noncurrent\_expiration\_rule\_days) | Number of days after which to expunge the objects | `string` | `"30"` | no |
| <a name="input_noncurrent_expiration_rule_enabled"></a> [noncurrent\_expiration\_rule\_enabled](#input\_noncurrent\_expiration\_rule\_enabled) | Specifies whether expiration lifecycle rule for noncurrent versions is enabled. | `bool` | `false` | no |
| <a name="input_noncurrent_expiration_rule_prefix"></a> [noncurrent\_expiration\_rule\_prefix](#input\_noncurrent\_expiration\_rule\_prefix) | Specify prefix for non-current expiration rule. | `string` | `""` | no |
| <a name="input_noncurrent_glacier_rule_enabled"></a> [noncurrent\_glacier\_rule\_enabled](#input\_noncurrent\_glacier\_rule\_enabled) | Specifies whether the glacier lifecycle rule is enabled for noncurrent versions. | `bool` | `false` | no |
| <a name="input_noncurrent_glacier_rule_prefix"></a> [noncurrent\_glacier\_rule\_prefix](#input\_noncurrent\_glacier\_rule\_prefix) | Specifies prefix for the glacier lifecycle rule for noncurrent versions. | `string` | `""` | no |
| <a name="input_noncurrent_glacier_transition_days"></a> [noncurrent\_glacier\_transition\_days](#input\_noncurrent\_glacier\_transition\_days) | Specifies transition days for the glacier lifecycle rule for noncurrent versions. | `number` | `30` | no |
| <a name="input_noncurrent_onezone_rule_enabled"></a> [noncurrent\_onezone\_rule\_enabled](#input\_noncurrent\_onezone\_rule\_enabled) | Specifies whether the onezone\_ia lifecycle rule is enabled for noncurrent versions. | `bool` | `false` | no |
| <a name="input_noncurrent_onezone_rule_prefix"></a> [noncurrent\_onezone\_rule\_prefix](#input\_noncurrent\_onezone\_rule\_prefix) | Specifies prefix for the onezone\_ia lifecycle rule for noncurrent versions. | `string` | `""` | no |
| <a name="input_noncurrent_onezone_transition_days"></a> [noncurrent\_onezone\_transition\_days](#input\_noncurrent\_onezone\_transition\_days) | Specifies transition days for the onezone\_ia lifecycle rule for noncurrent versions. | `number` | `30` | no |
| <a name="input_noncurrent_standard_rule_enabled"></a> [noncurrent\_standard\_rule\_enabled](#input\_noncurrent\_standard\_rule\_enabled) | Specifies whether the standard lifecycle rule is enabled for noncurrent versions. | `bool` | `false` | no |
| <a name="input_noncurrent_standard_rule_prefix"></a> [noncurrent\_standard\_rule\_prefix](#input\_noncurrent\_standard\_rule\_prefix) | Specifies prefix for the standard lifecycle rule for noncurrent versions. | `string` | `""` | no |
| <a name="input_noncurrent_standard_transition_days"></a> [noncurrent\_standard\_transition\_days](#input\_noncurrent\_standard\_transition\_days) | Specifies transition days for the standard lifecycle rule for noncurrent versions. | `number` | `30` | no |
| <a name="input_object_lock_mode"></a> [object\_lock\_mode](#input\_object\_lock\_mode) | Mode to set for object lock. Valid values are 'GOVERNANCE' and 'COMPLIANCE'. Default is 'COMPLIANCE' | `string` | `"COMPLIANCE"` | no |
| <a name="input_object_lock_retention_days"></a> [object\_lock\_retention\_days](#input\_object\_lock\_retention\_days) | (Optional, Required if object\_lock\_retention\_years is not specified) The number of days that you want to specify for the default retention period. | `number` | `-1` | no |
| <a name="input_object_lock_retention_years"></a> [object\_lock\_retention\_years](#input\_object\_lock\_retention\_years) | (Optional, Required if object\_lock\_retention\_days is not specified) The number of years that you want to specify for the default retention period | `number` | `-1` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | S3 Bucket Ownership Controls | `string` | `"BucketOwnerEnforced"` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | A json policy document | `string` | `""` | no |
| <a name="input_project"></a> [project](#input\_project) | Specify to which project this resource belongs | `string` | `""` | no |
| <a name="input_projectID"></a> [projectID](#input\_projectID) | Specify to which project this resource belongs, tag is used for cost allocation | `string` | `""` | no |
| <a name="input_queues"></a> [queues](#input\_queues) | map of <queue\_arn>, OPTIONAL: list of <events> (defaults to [s3:ObjectCreated:*]) for which to send notifications, [filter\_prefix] and [filter\_suffix]. | <pre>map(object({<br>    queue_arn     = string<br>    events        = list(string)<br>    filter_prefix = optional(string)<br>    filter_suffix = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | Whether Amazon S3 should restrict public bucket policies for this bucket. | `bool` | `true` | no |
| <a name="input_s3_bucket_acl"></a> [s3\_bucket\_acl](#input\_s3\_bucket\_acl) | Private or Public | `string` | `"private"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the bucket | `string` | n/a | yes |
| <a name="input_tags_kms"></a> [tags\_kms](#input\_tags\_kms) | Instance specific Tags for S3 kms key | `map(string)` | `{}` | no |
| <a name="input_tags_s3"></a> [tags\_s3](#input\_tags\_s3) | Instance specific Tags for s3 bucket | `map(string)` | `{}` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | map of <topic\_arn>, OPTIONAL: list of <events> (defaults to [s3:ObjectCreated:*]) for which to send notifications, [filter\_prefix] and [filter\_suffix]. | <pre>map(object({<br>    topic_arn     = string<br>    events        = list(string)<br>    filter_prefix = optional(string)<br>    filter_suffix = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_use_aes256_encryption"></a> [use\_aes256\_encryption](#input\_use\_aes256\_encryption) | Boolean value to tell if the AES256 encryption should be used | `bool` | `false` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Specifies whether versioning is enabled for the S3 bucket. | `bool` | `false` | no |
| <a name="input_wa_number"></a> [wa\_number](#input\_wa\_number) | WA Number of the project | `string` | `"Not Set"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_kms_alias_arn"></a> [aws\_kms\_alias\_arn](#output\_aws\_kms\_alias\_arn) | n/a |
| <a name="output_aws_kms_alias_id"></a> [aws\_kms\_alias\_id](#output\_aws\_kms\_alias\_id) | n/a |
| <a name="output_aws_kms_alias_name"></a> [aws\_kms\_alias\_name](#output\_aws\_kms\_alias\_name) | n/a |
| <a name="output_aws_kms_key_arn"></a> [aws\_kms\_key\_arn](#output\_aws\_kms\_key\_arn) | n/a |
| <a name="output_aws_kms_key_id"></a> [aws\_kms\_key\_id](#output\_aws\_kms\_key\_id) | n/a |
| <a name="output_aws_kms_key_is_enabled"></a> [aws\_kms\_key\_is\_enabled](#output\_aws\_kms\_key\_is\_enabled) | n/a |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | n/a |
| <a name="output_s3_arn"></a> [s3\_arn](#output\_s3\_arn) | n/a |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | n/a |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | n/a |
| <a name="output_s3_id"></a> [s3\_id](#output\_s3\_id) | n/a |
| <a name="output_s3_region"></a> [s3\_region](#output\_s3\_region) | n/a |
| <a name="output_s3_tags"></a> [s3\_tags](#output\_s3\_tags) | n/a |
| <a name="output_s3_versioning"></a> [s3\_versioning](#output\_s3\_versioning) | n/a |
<!-- END_TF_DOCS -->
