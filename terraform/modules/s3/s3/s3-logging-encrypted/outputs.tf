output "s3_arn" {
  value = try(aws_s3_bucket.this[0].arn, "")
}

output "s3_id" {
  value = try(aws_s3_bucket.this[0].id, "")
}

output "s3_bucket" {
  value = try(aws_s3_bucket.this[0].bucket, "")
}

output "s3_bucket_domain_name" {
  value = try(aws_s3_bucket.this[0].bucket_domain_name, "")
}

output "s3_bucket_regional_domain_name" {
  value = try(aws_s3_bucket.this[0].bucket_regional_domain_name, "")
}

output "s3_region" {
  value = try(aws_s3_bucket.this[0].region, "")
}

output "s3_versioning" {
  value = flatten(aws_s3_bucket.this[*].versioning)
}

output "s3_tags" {
  # there's a bug from terraform preventing a more readable:
  # merge(aws_s3_bucket.this[*].tags...)
  # https://github.com/hashicorp/terraform/issues/22404
  value = merge(flatten([aws_s3_bucket.this[*].tags])...)
}

output "aws_kms_key_arn" {
  value = local.kms_key_arn
}

output "aws_kms_key_is_enabled" {
  value = try(aws_kms_key.this[0].is_enabled, "")
}

output "aws_kms_key_id" {
  value = try(aws_kms_key.this[0].key_id, "")
}

output "aws_kms_alias_arn" {
  value = try(aws_kms_alias.this[0].arn, "")
}

output "aws_kms_alias_name" {
  value = try(aws_kms_alias.this[0].name, "")
}

output "aws_kms_alias_id" {
  value = try(aws_kms_alias.this[0].id, "")
}

output "enabled" {
  value = var.enable
}
