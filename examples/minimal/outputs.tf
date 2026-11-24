output "primary_upload_bucket" {
  description = "Primary S3 bucket name where CI/CD pipelines should upload static builds"
  value       = module.mrap_static_site.primary_upload_bucket
}

output "primary_upload_region" {
  description = "AWS region of the primary S3 upload bucket"
  value       = module.mrap_static_site.primary_upload_region
}

output "active_bucket_regions" {
  description = "Active S3 bucket regions registered with the Multi-Region Access Point"
  value       = module.mrap_static_site.active_bucket_regions
}

output "mrap_arn" {
  description = "ARN of the S3 Multi-Region Access Point"
  value       = module.mrap_static_site.mrap_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.mrap_static_site.cloudfront_distribution_id
}

output "site_urls" {
  description = "Configured HTTPS URLs served by CloudFront"
  value       = module.mrap_static_site.site_urls
}
