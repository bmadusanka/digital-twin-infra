data "aws_caller_identity" "current" {}

module "project_kms_key" {
  source                 = "git::ssh://git@github.com/bmadusanka/modules.git//kms?ref=main"
  stage                  = var.stage
  project                = var.project
  description            = "General purpose usage in wcmaiftmvp"
  name                   = ""
  enable_config_recorder = false
  aws_service_configurations = [{
    simpleName  = "Logs",
    identifiers = ["logs.${var.aws_region}.amazonaws.com"],
    values      = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"],
    variable    = "kms:EncryptionContext:aws:logs:arn"
  }]
}

module "labels" {
  source         = "git::ssh://git@github.com/bmadusanka/modules.git//labels?ref=main"
  git_repository = var.git_repository
  project        = var.project
  stage          = var.stage
  layer          = var.stage
  resources = [
    "consultation-app",
    "apprunner-ecr-access-role"
  ]
}
