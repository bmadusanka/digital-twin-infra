# `bucket-policy`

This is a convenience module to assign bucket policies to a bucket.
It can be used to easily attach default policies to a bucket. Additional custom policies can be added via the
`policy` variable.
If none of the default policies should be attached, it is easier to use the `aws_s3_bucket_policy` terraform resource
directly.

### Usage

```terraform

module "my_s3_bucket" {
  source = "git::ssh://cap-tf-module-aws-s3-bucket/vwdfive/cap-tf-module-aws-s3-bucket//s3/s3-logging-encrypted?ref=tags/0.5.0"
  enable = true

  region                        = var.aws_region
  environment                   = var.environment
  project                       = var.project
  s3_bucket_name                = "my_s3_bucket"
  s3_bucket_acl                 = "private"
  target_bucket_id              = module.logs_bucket.s3_id
  versioning_enabled            = true
  enforce_SSL_encryption_policy = false # !!! policy variables have to be disabled
  allow_appflow_policy          = false # !!! policy variables have to be disabled
  policy                        = null  # !!! policy variables have to be disabled
  force_destroy                 = local.in_workspaces
  git_repository                = "vwdfive/myrepo"
}

module "my_s3_bucket_policy" {
  source = "git::ssh://cap-tf-module-aws-s3-bucket/vwdfive/cap-tf-module-aws-s3-bucket//s3/bucket-policy?ref=tags/0.5.0"

  enable                            = true
  bucket_name                       = module.my_s3_bucket.id
  enforce_ssl_encryption_policy     = true
  policy                            = data.aws_iam_policy_document.test.json
  enforce_kms_encryption_key_policy = true
  kms_encryption_key_arn            = module.my_s3_bucket.aws_kms_key_arn
}

data "aws_iam_policy_document" "my_bucket_policy" {
  statement {
    sid    = "denyOutdatedTLS"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      module.my_s3_bucket.s3_arn,
      "${module.my_s3_bucket.s3_arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values = [
        "1.2"
      ]
    }
  }
}
```

### Note

Only one policy can be attached to a bucket. This means that no policy variables should be set for s3 buckets
created with terraform modules from this bucket.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.57 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.57 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_iam_policy_document.allow_appflow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.combined](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.enforce_kms_encryption_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.enforce_ssl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.read_only_access_for_aws_principals_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_appflow_policy"></a> [allow\_appflow\_policy](#input\_allow\_appflow\_policy) | Whether or not to add a statement to the bucket policy allowing appflow to list the bucket and get object. | `bool` | `false` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the bucket to which to apply the policy | `string` | n/a | yes |
| <a name="input_enable"></a> [enable](#input\_enable) | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| <a name="input_enforce_kms_encryption_key_policy"></a> [enforce\_kms\_encryption\_key\_policy](#input\_enforce\_kms\_encryption\_key\_policy) | Allow only this KMS encryption key to put objects in to the bucket (set kms\_encryption\_key\_arn) | `bool` | `false` | no |
| <a name="input_enforce_ssl_encryption_policy"></a> [enforce\_ssl\_encryption\_policy](#input\_enforce\_ssl\_encryption\_policy) | Attach Bucket policy to force SSL encryption | `bool` | `false` | no |
| <a name="input_kms_encryption_key_arn"></a> [kms\_encryption\_key\_arn](#input\_kms\_encryption\_key\_arn) | KMS key that is enforced when enforce\_kms\_encryption\_key\_policy is true | `string` | `""` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | A json policy document | `string` | `null` | no |
| <a name="input_read_only_access_for_aws_principals_policy"></a> [read\_only\_access\_for\_aws\_principals\_policy](#input\_read\_only\_access\_for\_aws\_principals\_policy) | Grant ListBucket, ListBucketVersions, GetObject, GetObjectVersions permissions for all objects to the aws principals | `list(string)` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
