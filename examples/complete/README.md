# Complete 17-Region MRAP Static Site Example

This example provisions the full 17-region default S3 + Multi-Region Access Point (MRAP) static-site stack with custom CloudFront error responses (`404` -> `/404.html`), configurable noncurrent version lifecycle retention, viewer-request edge routing (apex-to-`www` 301 redirect and directory index rewriting), and resource tagging.

## Prerequisites

- An existing public Route 53 Hosted Zone for `example.com` (replace `example.com` with your own domain before applying).
- AWS credentials configured in your environment with permissions to manage S3, S3 Control (MRAP), IAM, ACM, Route 53, and CloudFront.
- Terraform `>= 1.10.0`.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

| Name | Description |
| :--- | :--- |
| `primary_upload_bucket` | Primary S3 bucket name where CI/CD pipelines should upload static builds |
| `primary_upload_region` | AWS region of the primary S3 upload bucket |
| `active_bucket_regions` | List of all active S3 bucket regions registered with the Multi-Region Access Point |
| `bucket_names` | Map of AWS region to S3 bucket name for all active buckets in the Multi-Region Access Point mesh |
| `mrap_alias` | Global alias of the S3 Multi-Region Access Point |
| `mrap_domain_name` | Global domain name of the S3 Multi-Region Access Point |
| `mrap_arn` | ARN of the S3 Multi-Region Access Point |
| `cloudfront_distribution_id` | CloudFront Distribution ID (for CI/CD cache invalidations) |
| `cloudfront_distribution_arn` | ARN of the CloudFront distribution |
| `cloudfront_domain_name` | CloudFront Distribution default domain name (`*.cloudfront.net`) |
| `acm_certificate_arn` | ARN of the validated ACM SSL/TLS certificate in `us-east-1` |
| `site_urls` | Configured HTTPS URLs served by CloudFront |
