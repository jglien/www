output "url" {
  description = "Site URL"
  value       = "https://${local.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "s3_bucket" {
  description = "S3 assets bucket name"
  value       = aws_s3_bucket.assets.id
}

output "lambda_function_name" {
  description = "Lambda SSR function name"
  value       = aws_lambda_function.server.function_name
}
