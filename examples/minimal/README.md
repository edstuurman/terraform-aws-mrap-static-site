# Minimal 3-Region MRAP Static Site Example

This example provisions a global static website backed by a 3-region active-active S3 Multi-Region Access Point (MRAP) mesh (`ap-northeast-1` primary, plus `us-east-1` and `eu-west-1` replicas), CloudFront with native SigV4a Origin Access Control, an automatically DNS-validated ACM certificate in `us-east-1`, and Route 53 alias records.

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
| `active_bucket_regions` | Active S3 bucket regions registered with the Multi-Region Access Point |
| `mrap_arn` | ARN of the S3 Multi-Region Access Point |
| `cloudfront_distribution_id` | CloudFront Distribution ID |
| `site_urls` | Configured HTTPS URLs served by CloudFront |
