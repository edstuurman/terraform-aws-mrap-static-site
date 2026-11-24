output "primary_upload_bucket" {
  description = "Primary S3 bucket name where CI/CD pipelines should upload static builds"
  value       = module.mrap_static_site.primary_upload_bucket
}

output "primary_upload_region" {
  description = "AWS region of the primary S3 upload bucket"
  value       = module.mrap_static_site.primary_upload_region
}

output "active_bucket_regions" {
  description = "List of all active S3 bucket regions registered with the Multi-Region Access Point"
  value       = module.mrap_static_site.active_bucket_regions
}

output "bucket_names" {
  description = "Map of AWS region to S3 bucket name for all active buckets in the Multi-Region Access Point mesh"
  value       = module.mrap_static_site.bucket_names
}

output "mrap_alias" {
  description = "Global alias of the S3 Multi-Region Access Point"
  value       = module.mrap_static_site.mrap_alias
}

output "mrap_domain_name" {
  description = "Global domain name of the S3 Multi-Region Access Point"
  value       = module.mrap_static_site.mrap_domain_name
}

output "mrap_arn" {
  description = "ARN of the S3 Multi-Region Access Point"
  value       = module.mrap_static_site.mrap_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID (for CI/CD cache invalidations)"
  value       = module.mrap_static_site.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.mrap_static_site.cloudfront_distribution_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution default domain name (*.cloudfront.net)"
  value       = module.mrap_static_site.cloudfront_domain_name
}

output "acm_certificate_arn" {
  description = "ARN of the validated ACM SSL/TLS certificate in us-east-1"
  value       = module.mrap_static_site.acm_certificate_arn
}

output "site_urls" {
  description = "Configured HTTPS URLs served by CloudFront"
  value       = module.mrap_static_site.site_urls
}
