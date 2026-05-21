resource "aws_cloudfront_cache_policy" "this" {
  for_each = { for each in var.cache_policies : each.name => each }

  name        = each.value.name
  comment     = lookup(each.value, "comment", null)
  default_ttl = lookup(each.value, "default_ttl", null)
  max_ttl     = lookup(each.value, "max_ttl", null)
  min_ttl     = each.value.min_ttl
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = each.value.cookies_config["cookie_behavior"]
      cookies {
        items = each.value.cookies_config["items"]
      }
    }
    headers_config {
      header_behavior = each.value.headers_config["header_behavior"]
      headers {
        items = each.value.headers_config["items"]
      }
    }
    query_strings_config {
      query_string_behavior = each.value.query_strings_config["query_string_behavior"]
      query_strings {
        items = each.value.query_strings_config["items"]
      }
    }
    enable_accept_encoding_brotli = lookup(each.value, "enable_accept_encoding_brotli", null)
    enable_accept_encoding_gzip   = lookup(each.value, "enable_accept_encoding_gzip", null)
  }
}

resource "aws_cloudfront_origin_request_policy" "this" {
  for_each = { for each in var.origin_request_policies : each.name => each }
  name     = each.value.name
  comment  = lookup(each.value, "comment", null)
  cookies_config {
    cookie_behavior = each.value.cookies_config["cookie_behavior"]
    cookies {
      items = each.value.cookies_config["items"]
    }
  }
  headers_config {
    header_behavior = each.value.headers_config["header_behavior"]
    headers {
      items = each.value.headers_config["items"]
    }
  }
  query_strings_config {
    query_string_behavior = each.value.query_strings_config["query_string_behavior"]
    query_strings {
      items = each.value.query_strings_config["items"]
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "this" {
  for_each = { for each in var.response_header_policies : each.name => each }
  name     = each.value.name
  comment  = each.value.comment

  dynamic "custom_headers_config" {
    for_each = each.value.custom_headers == null ? [] : [each.value.custom_headers]
    iterator = i

    content {
      dynamic "items" {
        for_each = i.value.items

        content {
          header   = items.value.header
          override = items.value.override
          value    = items.value.header_value
        }
      }
    }
  }

  dynamic "cors_config" {
    for_each = each.value.cors == null ? [] : [each.value.cors]

    content {
      access_control_allow_credentials = cors_config.value.access_control_allow_credentials
      access_control_max_age_sec       = lookup(cors_config.value, "access_control_max_age_sec", 600)
      origin_override                  = cors_config.value.origin_override

      access_control_allow_headers {
        items = cors_config.value.allow_headers
      }

      access_control_allow_methods {
        items = cors_config.value.allow_methods
      }

      access_control_allow_origins {
        items = cors_config.value.allow_origins
      }

      dynamic "access_control_expose_headers" {
        for_each = lookup(cors_config.value, "expose_headers", null) == null ? [] : [cors_config.value.expose_headers]
        iterator = j

        content {
          items = j.value.expose_header_items
        }
      }
    }
  }

  dynamic "remove_headers_config" {
    for_each = each.value.remove_headers == null ? [] : [each.value.remove_headers]
    iterator = i

    content {
      dynamic "items" {
        for_each = i.value.items

        content {
          header = items.value.header
        }
      }
    }
  }

  dynamic "security_headers_config" {
    for_each = each.value.security_headers == null ? [] : [each.value.security_headers]
    iterator = i

    content {
      dynamic "content_security_policy" {
        for_each = i.value.content_security_policy == null ? [] : [i.value.content_security_policy]
        iterator = j

        content {
          content_security_policy = j.value.header_value
          override                = j.value.override
        }
      }

      dynamic "content_type_options" {
        for_each = i.value.content_type_options == null ? [] : [i.value.content_type_options]
        iterator = j

        content {
          override = j.value.override
        }
      }

      dynamic "frame_options" {
        for_each = i.value.frame_options == null ? [] : [i.value.frame_options]
        iterator = j

        content {
          frame_option = j.value.header_value
          override     = j.value.override
        }
      }

      dynamic "referrer_policy" {
        for_each = i.value.referrer_policy == null ? [] : [i.value.referrer_policy]
        iterator = j

        content {
          referrer_policy = j.value.header_value
          override        = j.value.override
        }
      }

      dynamic "strict_transport_security" {
        for_each = i.value.strict_transport_security == null ? [] : [i.value.strict_transport_security]
        iterator = j

        content {
          access_control_max_age_sec = j.value.access_control_max_age_sec
          include_subdomains         = lookup(j.value, "include_subdomains", null)
          override                   = j.value.override
          preload                    = lookup(j.value, "preload", null)
        }
      }

      dynamic "xss_protection" {
        for_each = i.value.xss_protection == null ? [] : [i.value.xss_protection]
        iterator = j

        content {
          mode_block = lookup(j.value, "mode_block", null)
          override   = j.value.override
          protection = j.value.protection
          report_uri = lookup(j.value, "report_uri", null)
        }
      }
    }
  }

  dynamic "server_timing_headers_config" {
    for_each = each.value.server_timing_headers == null ? [] : [each.value.server_timing_headers]
    iterator = i

    content {
      enabled       = i.value.enabled
      sampling_rate = i.value.sampling_rate
    }
  }
}

data "aws_cloudfront_cache_policy" "this" {
  for_each = toset([
    "Managed-Amplify", "Managed-CachingDisabled", "Managed-CachingOptimized",
    "Managed-CachingOptimizedForUncompressedObjects", "Managed-Elemental-MediaPackage"
  ])
  name = each.value
}

data "aws_cloudfront_origin_request_policy" "this" {
  for_each = toset([
    "Managed-AllViewer", "Managed-AllViewerAndCloudFrontHeaders-2022-06",
    "Managed-AllViewerExceptHostHeader", "Managed-CORS-CustomOrigin", "Managed-CORS-S3Origin",
    "Managed-Elemental-MediaTailor-PersonalizedManifests", "Managed-UserAgentRefererHeaders"
  ])
  name = each.value
}

data "aws_cloudfront_response_headers_policy" "this" {
  for_each = toset([
    "Managed-CORS-and-SecurityHeadersPolicy", "Managed-CORS-With-Preflight",
    "Managed-CORS-with-preflight-and-SecurityHeadersPolicy",
    "Managed-SecurityHeadersPolicy", "Managed-SimpleCORS"
  ])
  name = each.value
}

// Creates the s3 bucket for cloudfront logs
resource "aws_s3_bucket" "this" {
  bucket = var.logging_bucket
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_cloudfront_distribution" "this" {
  for_each = var.create_distribution ? { for each in var.distributions : each.distribution_name => each } : {}

  aliases             = each.value.aliases
  comment             = each.value.distribution_name
  default_root_object = each.value.default_root_object
  enabled             = each.value.enabled
  http_version        = each.value.http_version
  is_ipv6_enabled     = each.value.is_ipv6_enabled
  price_class         = each.value.price_class
  retain_on_delete    = each.value.retain_on_delete
  wait_for_deployment = each.value.wait_for_deployment
  web_acl_id          = lookup(each.value, "web_acl_id", null) == null ? (var.waf.enabled ? aws_wafv2_web_acl.this[0].arn : null) : each.value.web_acl_id
  tags                = each.value.tags

  dynamic "custom_error_response" {
    for_each = each.value.custom_error_response

    content {
      error_code = custom_error_response.value["error_code"]

      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
    }
  }

  dynamic "default_cache_behavior" {
    for_each = [each.value.default_cache_behavior]
    iterator = i

    content {
      target_origin_id       = i.value.target_origin_id
      viewer_protocol_policy = i.value.viewer_protocol_policy

      allowed_methods           = i.value.allowed_methods
      cached_methods            = i.value.cached_methods
      compress                  = i.value.compress
      field_level_encryption_id = i.value.field_level_encryption_id
      smooth_streaming          = i.value.smooth_streaming
      trusted_signers           = i.value.trusted_signers
      trusted_key_groups        = i.value.trusted_key_groups

      cache_policy_id            = startswith(i.value.cache_policy, "Managed-") ? data.aws_cloudfront_cache_policy.this[i.value.cache_policy].id : aws_cloudfront_cache_policy.this[i.value.cache_policy].id
      origin_request_policy_id   = i.value.origin_request_policy == null ? null : (startswith(i.value.origin_request_policy, "Managed-") ? data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy].id : aws_cloudfront_origin_request_policy.this[i.value.cache_policy].id)
      response_headers_policy_id = i.value.response_headers_policy == null ? null : (startswith(i.value.response_headers_policy, "Managed-") ? data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy].id : aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy].id)
      realtime_log_config_arn    = i.value.realtime_log_config_arn

      dynamic "lambda_function_association" {
        for_each = i.value.lambda_function_association
        iterator = l

        content {
          event_type   = l.value.event_type
          lambda_arn   = aws_lambda_function.this["${l.value.function_name}.zip"].qualified_arn
          include_body = lookup(l.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        for_each = i.value.function_association
        iterator = f

        content {
          event_type   = f.value.event_type
          function_arn = aws_cloudfront_function.this["${f.value.function_name}.js"].arn
        }
      }
    }
  }

  dynamic "logging_config" {
    for_each = lookup(each.value.logging_config, "enabled", false) ? [each.value.logging_config] : []

    content {
      bucket          = aws_s3_bucket.this.bucket_domain_name
      prefix          = each.value.distribution_name
      include_cookies = lookup(logging_config.value, "include_cookies", null)
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = each.value.ordered_cache_behavior
    iterator = i

    content {
      path_pattern           = i.value.path_pattern
      target_origin_id       = i.value.target_origin_id
      viewer_protocol_policy = i.value.viewer_protocol_policy

      allowed_methods           = i.value.allowed_methods
      cached_methods            = i.value.cached_methods
      compress                  = i.value.compress
      field_level_encryption_id = i.value.field_level_encryption_id
      smooth_streaming          = i.value.smooth_streaming
      trusted_signers           = i.value.trusted_signers
      trusted_key_groups        = i.value.trusted_key_groups

      cache_policy_id            = startswith(i.value.cache_policy, "Managed-") ? data.aws_cloudfront_cache_policy.this[i.value.cache_policy].id : aws_cloudfront_cache_policy.this[i.value.cache_policy].id
      origin_request_policy_id   = i.value.origin_request_policy == null ? null : (startswith(i.value.origin_request_policy, "Managed-") ? data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy].id : aws_cloudfront_origin_request_policy.this[i.value.cache_policy].id)
      response_headers_policy_id = i.value.response_headers_policy == null ? null : (startswith(i.value.response_headers_policy, "Managed-") ? data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy].id : aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy].id)
      realtime_log_config_arn    = i.value.realtime_log_config_arn

      dynamic "lambda_function_association" {
        for_each = i.value.lambda_function_association
        iterator = l

        content {
          event_type   = l.value.event_type
          lambda_arn   = aws_lambda_function.this["${l.value.function_name}.zip"].qualified_arn
          include_body = l.value.include_body
        }
      }

      dynamic "function_association" {
        for_each = i.value.function_association
        iterator = f

        content {
          event_type   = f.value.event_type
          function_arn = aws_cloudfront_function.this["${f.value.function_name}.js"].arn
        }
      }
    }
  }

  dynamic "origin" {
    for_each = { for each in each.value.origin : each.domain_name => each }

    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id == null ? origin.value.domain_name : origin.value.origin_id
      origin_path              = origin.value.origin_path
      connection_attempts      = origin.value.connection_attempts
      connection_timeout       = origin.value.connection_timeout
      origin_access_control_id = origin.value.custom_origin ? null : aws_cloudfront_origin_access_control.this.id

      dynamic "custom_header" {
        for_each = origin.value.custom_header

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin ? [origin.value.custom_origin_config] : []

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
          origin_read_timeout      = custom_origin_config.value.origin_read_timeout
        }
      }

      dynamic "origin_shield" {
        for_each = origin.value.origin_shield == null ? [] : [origin.value.origin_shield]

        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }
    }
  }

  dynamic "origin_group" {
    for_each = { for each in each.value.origin_group : each.origin_id => each }

    content {
      origin_id = origin_group.value.origin_id

      failover_criteria {
        status_codes = origin_group.value.failover_status_codes
      }

      member {
        origin_id = origin_group.value.primary_member_origin_id
      }

      member {
        origin_id = origin_group.value.secondary_member_origin_id
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = each.value.geo_restriction.restriction_type
      locations        = each.value.geo_restriction.locations
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.this["${each.value.viewer_certificate}.crt"].arn
    cloudfront_default_certificate = null
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_function" "this" {
  for_each = fileset("${var.path_to_cloudfront}/functions", "*.js")
  name     = trimsuffix(each.key, ".js")
  runtime  = "cloudfront-js-2.0"
  publish  = true
  code     = file("${var.path_to_cloudfront}/functions/${each.value}")
}

data "archive_file" "this" {
  for_each    = fileset("${var.path_to_cloudfront}/lambda-functions", "*.py")
  type        = "zip"
  source_file = "${var.path_to_cloudfront}/lambda-functions/${each.value}"
  output_path = "${var.path_to_cloudfront}/archived-functions/${trimsuffix(each.value, ".py")}.zip"
}


// Lambda@Edge functions for CloudFront have to be in us-east-1
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/automation-admin"
  }
}


// Create a WAFv2 Web ACL in us-east-1 for CloudFront when enabled
resource "aws_wafv2_web_acl" "this" {
  count      = var.waf.enabled ? 1 : 0
  provider   = aws.virginia
  name       = lookup(var.waf, "name", "cf-web-acl")
  description = "Web ACL for CloudFront distributions created by module"
  scope      = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = lookup(var.waf, "name", "cf-web-acl")
  }

  dynamic "rule" {
    for_each = var.waf.enabled ? values(var.waf.rules) : []
    iterator = r
    content {
      name     = r.value.name
      priority = r.value.priority

      dynamic "override_action" {
        for_each = lookup(r.value, "override_action", null) == "none" ? [1] : []
        content {
          none {}
        }
      }

      # Build a proper nested `statement` block from the provided map
      dynamic "statement" {
        for_each = lookup(r.value, "statement", null) == null ? [] : [r.value.statement]
        iterator = st
        content {
          # Support managed_rule_group_statement (the common case for AWS managed rules)
          dynamic "managed_rule_group_statement" {
            for_each = lookup(st.value, "managed_rule_group_statement", null) == null ? [] : [st.value.managed_rule_group_statement]
            iterator = m
            content {
              name        = m.value.name
              vendor_name = m.value.vendor_name

              # If user provided scope_down_statement inside the managed_rule_group_statement,
              # we try to pass through a simple byte_match_statement or other structures would need
              # additional handling. For now, we don't attempt to deep-map scope_down_statement.
            }
          }

          # Future: add support for other statement types (byte_match_statement, geo_match_statement, etc.) if needed.
        }
      }

      visibility_config {
        sampled_requests_enabled   = lookup(r.value.visibility_config, "sampled_requests_enabled", false)
        cloudwatch_metrics_enabled = lookup(r.value.visibility_config, "cloudwatch_metrics_enabled", false)
        metric_name                = lookup(r.value.visibility_config, "metric_name", r.value.name)
      }
    }
  }
}

resource "aws_lambda_function" "this" {
  for_each      = var.create_lambda_function ? fileset("${var.path_to_cloudfront}/archived-functions", "*.zip") : []
  filename      = "${var.path_to_cloudfront}/archived-functions/${each.value}"
  function_name = trimsuffix(each.value, ".zip")
  role          = aws_iam_role.this[0].arn
  handler       = "${trimsuffix(each.value, ".zip")}.lambda_handler"

  provider         = aws.virginia
  publish          = true
  runtime          = "python3.14"
  source_code_hash = data.archive_file.this["${trimsuffix(each.value, ".zip")}.py"].output_base64sha256
}

resource "aws_iam_policy" "this" {
  count       = var.create_iam ? 1 : 0
  name        = "AWSLambdaBasicExecutionRoleForCloudFront"
  description = "Used by CloudFront Distributions"
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:logs:*:${var.aws_account_id}:*"
      },
      {
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:logs:*:${var.aws_account_id}:log-group:/aws/lambda/*"
      }
    ]
  }
  EOF
}

data "aws_iam_policy_document" "this" {
  count = var.create_iam ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  count               = var.create_iam ? 1 : 0
  name                = "cf-lambda-role"
  assume_role_policy  = data.aws_iam_policy_document.this[0].json
}

resource "aws_iam_role_policy_attachment" "attach" {
  count      = var.create_iam ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "cloudfront-s3"
  description                       = "Access to s3 bucket created by CloudFront Terragrunt"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_secretsmanager_secret" "secrets" {
  for_each = fileset("${var.path_to_cloudfront}/certificates", "*.crt")

  name = format("%s%s%s", "cloudfront/", trimsuffix(each.key, ".crt"), ".key")
}

data "aws_secretsmanager_secret_version" "current" {
  for_each = fileset("${var.path_to_cloudfront}/certificates", "*.crt")

  secret_id = data.aws_secretsmanager_secret.secrets[each.key].id
}

resource "aws_acm_certificate" "this" {
  for_each = fileset("${var.path_to_cloudfront}/certificates", "*.crt")

  provider = aws.virginia

  private_key       = base64decode(jsondecode(data.aws_secretsmanager_secret_version.current[each.key].secret_string)["key"])
  certificate_body  = file(format("%s%s%s", "${var.path_to_cloudfront}/certificates/", trimsuffix(each.key, ".crt"), ".crt"))
  certificate_chain = file(format("%s%s%s", "${var.path_to_cloudfront}/certificates/", trimsuffix(each.key, ".crt"), ".chain"))
}
