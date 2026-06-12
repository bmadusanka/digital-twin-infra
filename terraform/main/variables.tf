variable "git_repository" {
  type        = string
  default     = "saas-infra"
  description = "Repository where the infrastructure was deployed from"
}

variable "stage" {
  description = "Specify to which project this resource belongs, no default value to allow proper validation of project setup"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Default Region for Cloud Platform"
  default     = "eu-central-1"
  type        = string
}

variable "project" {
  description = "Specify to which project this resource belongs"
  default     = "medica-ai"
  type        = string
}

variable "environment" {
  default = "dev"
  type    = string
}

variable "bedrock_model_id" {
  type        = string
  description = "Amazon BedRock Model ID"
  default     = "eu.amazon.nova-lite-v1:0"
}
