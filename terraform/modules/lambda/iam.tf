
data "aws_iam_role" "injected" {
  count = local.create_lambda_iam_role || !var.enable ? 0 : 1

  name = var.lambda_role_name
}


resource "aws_iam_role" "this" {
  count              = local.create_lambda_iam_role ? 1 : 0
  name               = lookup(module.lambda_label.resource["role"], "id")
  assume_role_policy = data.aws_iam_policy_document.this[count.index].json
  tags               = module.lambda_label.resource["role"]["tags"]
}

data "aws_iam_policy_document" "this" {
  count = local.create_lambda_iam_role ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "ec2policies" {
  #checkov:skip=CKV_AWS_356
  count = var.enable ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeNetworkInterfaces"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface"
    ]
    resources = [
      "arn:aws:ec2:${var.region}:${local.account_id}:*/*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_inline_policy" {
  count  = var.enable ? 1 : 0
  name   = module.lambda_policy_label.resource["inline"]["id"]
  role   = local.lambda_iam_role_name
  policy = data.aws_iam_policy_document.ec2policies[count.index].json
}

resource "aws_iam_role_policy_attachment" "this_logs" {
  count      = var.enable ? 1 : 0
  role       = local.lambda_iam_role_name
  policy_arn = aws_iam_policy.this_logs[count.index].arn
}

resource "aws_iam_policy" "this_logs" {
  count  = var.enable ? 1 : 0
  name   = lookup(module.lambda_policy_label.resource["base"], "id")
  policy = data.aws_iam_policy_document.this_logs[count.index].json
}

data "aws_iam_policy_document" "this_logs" {
  count = var.enable ? 1 : 0
  statement {
    effect = "Allow"
    sid    = "allowLoggingToCloudWatch"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      aws_cloudwatch_log_group.this[count.index].arn,
      "${aws_cloudwatch_log_group.this[count.index].arn}:*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:DescribeKey",
      "kms:ListKeys",
      "kms:GenerateDataKey",
    ]

    resources = [
      var.logs_kms_key_arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "aws_xray_write_only_process" {
  count      = local.create_lambda_iam_role && var.xray_mode == "Active" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  role       = aws_iam_role.this[0].name
}

# Possibility to attach another policy document
resource "aws_iam_policy" "this_additional" {
  count = var.enable && var.attach_additional_policy ? 1 : 0

  name   = lookup(module.lambda_policy_label.resource["add"], "id")
  policy = var.additional_policy
}

resource "aws_iam_role_policy_attachment" "this_additional" {
  count = var.enable && var.attach_additional_policy ? 1 : 0

  role       = local.lambda_iam_role_name
  policy_arn = aws_iam_policy.this_additional[count.index].arn
}
