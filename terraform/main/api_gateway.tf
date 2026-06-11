module "api" {
  source               = "git::ssh://git@github.com/bmadusanka/modules.git//api-gateway?ref=main"
  name                 = "twin-api"
  lambda_invoke_arn    = module.digital_twin_backend.aws_lambda_function_invoke_arn
  lambda_function_name = module.digital_twin_backend.aws_lambda_function_name

  cors = {
    allow_origins = ["*"]
    allow_headers = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    max_age       = 300
  }

  routes = [
    {
      method = "ANY"
      path   = "/{proxy+}"
    },
    {
      method = "GET"
      path   = "/"
    },
    {
      method = "GET"
      path   = "/health"
    },
    {
      method = "POST"
      path   = "/chat"
    },
    {
      method = "OPTIONS"
      path   = "/{proxy+}"
    }
  ]
}
