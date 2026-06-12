output "api_endpoint" {
  description = "The live HTTP URL of the API Gateway used by the frontend application."
  value       = module.api.api_endpoint
}
