variable "enable" {
  description = "Set to false to prevent the module from creating any resources"
  default     = true
  type        = bool
}

variable "enforce_ssl_encryption_policy" {
  description = "Attach Bucket policy to force SSL encryption"
  type        = bool
  default     = false
}

variable "allow_appflow_policy" {
  description = "Whether or not to add a statement to the bucket policy allowing appflow to list the bucket and get object."
  type        = bool
  default     = false
}

variable "read_only_access_for_aws_principals_policy" {
  description = "Grant ListBucket, ListBucketVersions, GetObject, GetObjectVersions permissions for all objects to the aws principals"
  default     = null
  type        = list(string)
}

variable "enforce_kms_encryption_key_policy" {
  description = "Allow only this KMS encryption key to put objects in to the bucket (set kms_encryption_key_arn)"
  type        = bool
  default     = false
}

variable "kms_encryption_key_arn" {
  description = "KMS key that is enforced when enforce_kms_encryption_key_policy is true"
  type        = string
  default     = ""
}

variable "policy" {
  description = "A json policy document"
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Name of the bucket to which to apply the policy"
  type        = string
}
