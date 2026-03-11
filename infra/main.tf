locals {
  root_domain = "johnlien.me"
  domain_name = var.stage == "prod" ? local.root_domain : "${var.stage}.${local.root_domain}"
  name_prefix = "www-${var.stage}"
}

# ------------------------------------------------------------------------------
# S3
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "assets" {
  bucket = "${local.name_prefix}-johnlien-me-assets"
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${local.name_prefix}-assets-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets_bucket.json
}

data "aws_iam_policy_document" "assets_bucket" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

# ------------------------------------------------------------------------------
# Lambda
# ------------------------------------------------------------------------------

data "archive_file" "server" {
  type        = "zip"
  source_dir  = "${path.root}/../dist/lambda"
  output_path = "${path.root}/../dist/lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "server" {
  function_name    = "${local.name_prefix}-server"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs24.x"
  handler          = "entry.handler"
  filename         = data.archive_file.server.output_path
  source_code_hash = data.archive_file.server.output_base64sha256
  timeout          = 10
  memory_size      = 1024
}

resource "aws_lambda_function_url" "server" {
  function_name      = aws_lambda_function.server.function_name
  authorization_type = "NONE"
}

# ------------------------------------------------------------------------------
# ACM + Route53
# ------------------------------------------------------------------------------

data "aws_route53_zone" "site" {
  name = local.root_domain
}

resource "aws_acm_certificate" "site" {
  provider          = aws.us_east_1
  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.site.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "site" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_aaaa" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = local.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# ------------------------------------------------------------------------------
# CloudFront
# ------------------------------------------------------------------------------

# Mirrors CloudFront's built-in CORS_ALLOW_ALL_ORIGINS_AND_SECURITY_HEADERS policy
resource "aws_cloudfront_response_headers_policy" "site" {
  name = "${local.name_prefix}-headers"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers { items = ["*"] }
    access_control_allow_methods { items = ["ALL"] }
    access_control_allow_origins { items = ["*"] }
    origin_override = true
  }

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  http_version        = "http2and3"
  price_class         = "PriceClass_All"
  aliases             = [local.domain_name]
  wait_for_deployment = false

  # Lambda Function URL origin (SSR)
  origin {
    origin_id   = "lambda"
    domain_name = replace(aws_lambda_function_url.server.function_url, "/^https?://([^/]*).*/", "$1")

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # S3 origin (static assets)
  origin {
    origin_id                = "s3"
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  # Public folder assets served from S3
  dynamic "ordered_cache_behavior" {
    for_each = ["/favicons/*", "/images/*", "/fonts/*"]
    content {
      path_pattern               = ordered_cache_behavior.value
      target_origin_id           = "s3"
      viewer_protocol_policy     = "redirect-to-https"
      allowed_methods            = ["GET", "HEAD"]
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
      response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
    }
  }

  # Static assets (/_astro/*) served from S3 with long-lived cache
  ordered_cache_behavior {
    path_pattern               = "/_astro/*"
    target_origin_id           = "s3"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
  }

  # Default: SSR via Lambda
  default_cache_behavior {
    target_origin_id           = "lambda"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id   = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
}
