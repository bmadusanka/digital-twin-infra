output "api_endpoint" {
  description = "The live HTTP URL of the API Gateway used by the frontend application."
  value       = module.api.api_endpoint
}

output "cloudfront_uri" {
  description = "The live HTTP URL of the frontend application."
  value       = resource.aws_cloudfront_distribution.this.domain_name
}
