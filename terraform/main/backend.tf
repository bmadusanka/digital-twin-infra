terraform {
  backend "s3" {
    bucket       = "udemy-mlops-labs-terraform-state"
    key          = "udemy/mlops/digital-twin/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
