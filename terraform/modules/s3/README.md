# Terraform Module: AWS S3

[`s3-encrypted`]: s3/s3-encrypted/README.md
[`s3-logging-encrypted`]: s3/s3-logging-encrypted/README.md
[`bucket-policy`]: s3/bucket-policy/README.md

* [Usage](#usage)
  * [Module Usage](#module-usage)
* [Requirements](#requirements)
* [Providers](#providers)
* [Inputs](#inputs)
* [Outputs](#outputs)

## Usage

Currently, the CAP project uses different SSH Deploy Keys, each unique to its module repo. For this reason, referencing
to the current module from any of the CAP related projects, the developer needs to setup an entry in the SSH Config to
create a unique alias for the module.

### SSH Config
In the scenario where the Private SSH Deploy Key is stored in ~/.ssh/cap-tf-module-aws-s3-bucket, then the entry in the SSH config file (typically in ~/.ssh/config) could look like:

```
Host cap-tf-module-aws-s3-bucket
  HostName github.com
  User git
  IdentityFile ~/.ssh/cap-tf-module-aws-s3-bucket
```

Doing so, will let any application using SSH (including Terraform) refer to the module with with cap-tf-module-aws-s3-bucket as hostname instead of github.com. For example, the developer could now download the repository with:

```
git clone cap-tf-module-aws-s3-bucket:vwdfive/cap-tf-module-aws-s3-bucket.git
```

### Module Usage
There are 4 different modules you can use. Below its the example of using s3-logging-encrypted, which is used to have encrypted logs.
s3-website can be used to deploy a website from a s3 bucket.
s3-simple is the basic model of using s3 buckets.
If you want to use another module, in source section, you should i.e replace //s3/s3-logging-encrypted with //s3/s3-website
The current implementation of s3-bucket modules in the original `cap-consumer-ap`

(notice usage of the repo path of the module + tag version)
```hcl-terraform
module "s3-bucket" {
  source = "git::ssh://cap-tf-module-aws-s3-bucket/vwdfive/cap-tf-module-aws-s3-bucket//s3/s3-logging-encrypted?ref=tags/0.3.6"
  enable = local.in_default_workspace

  region                       = var.aws_region
  environment                  = var.environment
  project                      = var.project
  s3_bucket_name               = var.s3_vcf_bucket_data
  s3_bucket_acl                = "private"
  target_bucket_id             = module.logs_bucket.s3_id
  versioning_enabled           = true
  enforce_SSL_encyption_policy = true
  force_destroy                = local.in_workspaces

  ### Default Lifecycle rules
  noncurrent_glacier_rule_enabled    = true
  noncurrent_glacier_transition_days = 30
  current_standard_rule_enabled      = true
  current_standard_transition_days   = 60
  current_glacier_rule_enabled       = true
  current_glacier_transition_days    = 120

  ### New dynamically created Lifecycle rules
  lifecycle_rules = [
    {
      enabled = true
      prefix  = "log/redshift-logs/"
      transitions = [
        {
          days          = 30
          storage_class = var.lifecycle_standard_ia_storage_class
        },
        {
          days          = 90
          storage_class = var.lifecycle_glacier_storage_class
        },
        {
          days          = 365
          storage_class = var.lifecycle_deep_archive_storage_class
        }
      ]
      expirations                    = [{ days = 1800 }]
      noncurrent_version_expirations = [{ days = 14 }]
    },
    {
      enabled                        = true
      prefix                         = "log/ecs-logs/"
      expirations_with_date          = [{ date = "2025-06-07T00:00:00Z" }]
      noncurrent_version_expirations = [{ days = 14 }]
    },
    {
      enabled                        = true
      prefix                         = "log/dynamodb-logs/"
      expirations                    = [{ days = 30 }]
      noncurrent_version_expirations = [{ days = 14 }]
    }
  ]

  kst = var.kst
  wa_number = var.wa_number
  policy_json = data.aws_iam_policy_document.s3_vcf_bucket_data.json
  lambda_functions = {
    s3_to_ecs = {
      lambda_function_arn = module.s3_to_ecs.aws_lambda_function_arn
      filter_prefix = local.salesforce_s3_prefix
      filter_suffix = local.parquet_suffix
    },
    s3_to_redshift = {
      lambda_function_arn = module.s3_to_redshift.aws_lambda_function_arn
      filter_prefix = local.adobe_analytics_s3_prefix
      filter_suffix = local.filter_suffix
    }
  }

}
```

#### Note about Lifecycle rules:
As of repo release 0.4.3 the s3 bucket's lifecycle rules can be created dynamically by alternatively using the `lifecycle_rules` variable, besides to using the default defined lifecycle rules. This allows dynamical creation of multiple lifecycle rules of the same type, with different prefixes, in the same bucket. When `lifecycle_rules` is used, at least one of the transitions/expirations must be specified.
<br>If `prefix` is omitted, the respective rule is applied to all objects in the **entire** bucket.
<br>Transitions (for current and non-current versions) are to be implemented with number of days, and the storage class the objects will be transitioned ***to***. Storage class must be one of: `ONEZONE_IA`, `STANDARD_IA`, `INTELLIGENT_TIERING`, `GLACIER` or `DEEP_ARCHIVE`.
<br>Expirations (for current and non-current versions) are to be implemented with number of days only.

### Update about Lifecycle rules:
<br> With new implementation, Current Version Expiration is implemented with date as well.
<br> Please note that you can only use either day or date implementation in the same lifecycle rule.
<br> If you need to use both of them, simply use two lifecycle rules.

### Bucket policies

If one of the variables that enable a policy is set (`policy`, `enforce_SSL_encryption_policy`, `allow_appflow_policy`),
the module creates a policy and attaches it to the bucket.
This means that **no** other policy can be attached outside this module.
If a policy is attached via `aws_s3_bucket_policy` the behavior is unpredictable, i.e. it's random which policy will be used,
and it can change from deployment to deployment.

If there is the need of a more custom policy, all policy variables (`policy`, `enforce_SSL_encryption_policy`, `allow_appflow_policy`)
**must not** be set and the full policy has to be created and attached outside the module.

### Future Usage

After complete module extraction, all S3 bucket modules will be combined into a single module, where one of the attributes will refer to the type of module in usage.

Biggest reason for not doing this for previously created buckets at the same time of module extraction is to prevent unintended changes to existing resources and separation of concerns (module extraction vs. module improvements)



Modules
---

See the dedicated READMEs for the following modules:
* [`s3-encrypted`]
* [`s3-logging-encrypted`]
* [`bucket-policy`]
