
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      OrgScope        = "Not Set"
      FunctionalScope = "Not Set"
      Environment     = "Not Set"
      ModuleName      = "Not Set"
      GitRepository   = var.git_repository
      ProjectID       = var.project
    }
  }
}