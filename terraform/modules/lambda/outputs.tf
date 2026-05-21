output "lambda_zip_id" {
  value = var.package_type == "Zip" ? join("", aws_lambda_function.lambda.*.s3_key) : ""
}

output "aws_lambda_function_name" {
  value = join("", aws_lambda_function.lambda.*.function_name)
}

output "aws_lambda_function_arn" {
  value = join("", aws_lambda_function.lambda.*.arn)
}

output "aws_lambda_function_kms_key_arn" {
  value = join("", aws_lambda_function.lambda.*.kms_key_arn)
}

output "aws_lambda_function_role_arn" {
  value = local.create_lambda_iam_role ? try(aws_iam_role.this[0].arn, "") : try(data.aws_iam_role.injected[0].arn, "")
}

output "aws_lambda_function_role_name" {
  value = local.create_lambda_iam_role ? try(aws_iam_role.this[0].name, "") : try(data.aws_iam_role.injected[0].name, "")
}

output "aws_lambda_function_handler" {
  value = var.package_type == "Zip" ? join("", aws_lambda_function.lambda.*.handler) : ""
}

output "aws_cloudwatch_log_group_arn" {
  value = join("", aws_cloudwatch_log_group.this.*.arn)
}

output "aws_cloudwatch_log_group_name" {
  value = join("", aws_cloudwatch_log_group.this.*.name)
}

output "aws_cloudwatch_log_group_id" {
  value = join("", aws_cloudwatch_log_group.this.*.id)
}

output "enable" {
  value = var.enable
}

output "aws_lambda_function_invoke_arn" {
  value = join("", aws_lambda_function.lambda.*.invoke_arn)
}

output "source_files" {
  value = var.package_type == "Zip" ? local.fileset : null
}
