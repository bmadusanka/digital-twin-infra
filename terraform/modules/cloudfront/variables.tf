variable "aws_account_id" {
  type = string
}

variable "cache_policies" {
  type = list(object({
    name        = string
    comment     = optional(string)
    default_ttl = optional(number, 86400)
    max_ttl     = optional(number, 31536000)
    min_ttl     = optional(number, 1)
    cookies_config = object({
      cookie_behavior = string
      items           = list(string)
    })
    headers_config = object({
      header_behavior = string
      items           = list(string)
    })
    query_strings_config = object({
      query_string_behavior = string
      items                 = list(string)
    })
    enable_accept_encoding_brotli = optional(bool, true)
    enable_accept_encoding_gzip   = optional(bool, true)
  }))
  default = []
}

variable "create_iam" {
  type    = bool
  default = true
}

variable "create_distribution" {
  description = "Controls if CloudFront distribution identity should be created"
  type        = bool
  default     = true
}

variable "create_lambda_function" {
  type    = bool
  default = true
}

variable "distributions" {
  type = list(object({
    aliases = optional(list(string))
    custom_error_response = optional(list(object({
      error_code            = number
      response_code         = optional(number)
      response_page_path    = optional(string)
      error_caching_min_ttl = optional(number, 10)
    })), [])
    default_cache_behavior = object({
      target_origin_id          = string
      viewer_protocol_policy    = optional(string, "redirect-to-https")
      allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])
      cached_methods            = optional(list(string), ["GET", "HEAD"])
      compress                  = optional(bool, true)
      field_level_encryption_id = optional(string)
      smooth_streaming          = optional(bool)
      trusted_signers           = optional(any)
      trusted_key_groups        = optional(any)
      cache_policy              = string
      origin_request_policy     = optional(string)
      response_headers_policy   = optional(string)
      realtime_log_config_arn   = optional(string)
      lambda_function_association = optional(list(object({
        event_type    = string
        function_name = string
        include_body  = optional(bool, false)
      })), [])
      function_association = optional(list(map(string)), [])
    })
    default_root_object = optional(string)
    distribution_name   = string
    enabled             = optional(bool, true)
    geo_restriction = optional(any, {
      restriction_type = "none"
      locations        = []
    })
    http_version    = optional(string, "http2")
    is_ipv6_enabled = optional(bool, true)
    logging_config  = optional(any, {})
    ordered_cache_behavior = optional(list(object({
      path_pattern              = string
      target_origin_id          = string
      viewer_protocol_policy    = optional(string, "redirect-to-https")
      allowed_methods           = optional(list(string), ["GET", "HEAD", "OPTIONS"])
      cached_methods            = optional(list(string), ["GET", "HEAD"])
      compress                  = optional(bool, true)
      field_level_encryption_id = optional(string)
      smooth_streaming          = optional(bool)
      trusted_signers           = optional(any)
      trusted_key_groups        = optional(any)
      cache_policy              = string
      origin_request_policy     = optional(string)
      response_headers_policy   = optional(string)
      realtime_log_config_arn   = optional(string)
      lambda_function_association = optional(list(object({
        event_type    = string
        function_name = string
        include_body  = optional(bool, false)
      })), [])
      function_association = optional(list(map(string)), [])
    })), [])
    origin = list(object({
      domain_name              = string
      origin_id                = optional(string)
      origin_path              = optional(string, "")
      connection_attempts      = optional(number, 3)
      connection_timeout       = optional(number, 10)
      origin_access_control_id = optional(string)
      custom_header            = optional(list(map(string)), [])
      custom_origin            = optional(bool, true)
      custom_origin_config = optional(object({
        http_port                = optional(number, 80)
        https_port               = optional(number, 443)
        origin_protocol_policy   = optional(string, "https-only")
        origin_ssl_protocols     = optional(list(string), ["TLSv1", "TLSv1.1", "TLSv1.2"])
        origin_keepalive_timeout = optional(number, 60)
        origin_read_timeout      = optional(number, 60)
      }), {})
      origin_shield = optional(object({
        enabled              = bool
        origin_shield_region = optional(string, "eu-west-1")
      }))
    }))
    origin_group = optional(list(object({
      origin_id                  = string
      failover_status_codes      = optional(list(number), [400, 403, 404, 416, 500, 502, 503, 504])
      primary_member_origin_id   = string
      secondary_member_origin_id = string
    })), [])
    price_class         = optional(string, "PriceClass_All")
    retain_on_delete    = optional(bool, false)
    wait_for_deployment = optional(bool, false)
    web_acl_id          = optional(string)
    tags                = optional(map(string))
    viewer_certificate = optional(any, {
      cloudfront_default_certificate = true
      minimum_protocol_version       = "TLSv1"
    })
  }))
}

variable "logging_bucket" {
  type = string
}

variable "origin_request_policies" {
  type = list(object({
    name                 = string
    comment              = optional(string)
    cookies_config       = any
    headers_config       = any
    query_strings_config = any
  }))
  default = []
}

variable "path_to_cloudfront" {
  type = string
}

variable "response_header_policies" {
  type = list(object({
    name                  = string
    comment               = optional(string)
    cors                  = optional(any)
    custom_headers        = optional(any)
    remove_headers        = optional(any)
    security_headers      = optional(any)
    server_timing_headers = optional(any)
  }))
  default = []
}

variable "stage_name" {
  type = string
}

variable "waf" {
  description = "Configuration for AWS WAFv2 to attach to CloudFront. Use `rules` as a map of rule objects. Example structure in module README or docs."
  type = object({
    enabled = optional(bool, false)
    name    = optional(string)
    rules = optional(map(object({
      name              = string
      priority          = number
      override_action   = optional(string)
      statement         = any
      visibility_config = any
    })), {})
  })
  default = {
    enabled = false
    rules   = {}
  }
}
