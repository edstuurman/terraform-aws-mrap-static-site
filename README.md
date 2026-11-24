# terraform-aws-mrap-static-site

[![Terraform >= 1.10](https://img.shields.io/badge/Terraform-%3E%3D%201.10-7b42bc?style=for-the-badge&logo=terraform&logoColor=white&labelColor=111827)](https://developer.hashicorp.com/terraform)
[![AWS Provider ~> 6.0](https://img.shields.io/badge/AWS_Provider-~%3E%206.0-ff9900?style=for-the-badge&logo=amazonwebservices&logoColor=white&labelColor=111827)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![S3 MRAP + SigV4a OAC](https://img.shields.io/badge/S3_MRAP-CloudFront_SigV4a_OAC-d97706?style=for-the-badge&labelColor=111827)](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
[![MIT License](https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge&labelColor=111827)](./LICENSE)
[![Terraform CI](https://github.com/edstuurman/terraform-aws-mrap-static-site/actions/workflows/ci.yml/badge.svg)](https://github.com/edstuurman/terraform-aws-mrap-static-site/actions/workflows/ci.yml)

Terraform module to provision a globally replicated, active-active static site hosting stack on AWS using **S3 Multi-Region Access Points (MRAP)**, automated **S3 Cross-Region Replication (CRR)**, **CloudFront with native SigV4a Origin Access Control (OAC)**, **CloudFront Functions**, **ACM TLS certificates**, and **Route 53**.

## Key Capabilities

- **Single `provider "aws"` Block via AWS Provider v6 Per-Resource `region`**: Leverages the AWS Provider `~> 6.0` per-resource `region` attribute to provision up to **17 regional S3 buckets** and the **`us-east-1` ACM certificate** from a single default provider configuration—eliminating 17+ aliased `provider "aws"` blocks and keeping the module cleanly composable with `for_each`.
- **Native CloudFront SigV4a OAC (Zero Lambda@Edge)**: Uses CloudFront's native Signature Version 4a (SigV4a) Origin Access Control (`s3`) to authenticate requests directly against the S3 Multi-Region Access Point without Lambda@Edge signing proxies or public bucket policies.
- **Edge Routing via CloudFront Functions**: Lightweight `viewer-request` CloudFront Function handling optional apex-to-`www` `301` redirects and clean URL directory index rewrites (`/blog/` → `/blog/index.html`).
- **Automated Replication & Lifecycle**: Provisions S3 bucket versioning, SSE-S3 encryption, IAM replication role/policies, priority-ordered CRR rules from the primary upload bucket to all configured replicas, and noncurrent version expiration.
- **Turnkey DNS & TLS**: Automatically requests and DNS-validates a `us-east-1` ACM certificate and creates Route 53 IPv4 (`A`) and IPv6 (`AAAA`) alias records.

## Architecture

```text
                        ┌─────────────────────────────┐
                        │        Route 53 DNS         │
                        │  A / AAAA Alias Records     │
                        │  example.com, www.example   │
                        └──────────────┬──────────────┘
                                       │
                                       ▼
                        ┌─────────────────────────────┐
                        │    Amazon CloudFront        │
                        │  • ACM TLS (us-east-1)      │
                        │  • CloudFront Function      │
                        │    (301 apex→www, /index)   │
                        │  • SigV4a OAC (s3)          │
                        └──────────────┬──────────────┘
                                       │
                                       ▼
                        ┌─────────────────────────────┐
                        │  S3 Multi-Region Access Pt  │
                        │  (<alias>.accesspoint...)   │
                        └──────────────┬──────────────┘
                                       │
                 ┌─────────────────────┼─────────────────────┐
                 ▼                     ▼                     ▼
     ┌───────────────────────┐ ┌───────────────┐     ┌───────────────┐
     │  Primary S3 Bucket    │ │ Replica S3 #1 │     │ Replica S3 #N │
     │  (is_main = true)     ├─► (e.g. us-east)│ ... │ (up to 16     │
     │  Site deploys here    │ │  CRR Sync     │     │  replicas)    │
     └───────────────────────┘ └───────────────┘     └───────────────┘
```

## Usage

### Quick Start

```hcl
module "mrap_static_site" {
  source  = "edstuurman/mrap-static-site/aws"
  version = "~> 1.0"

  environment_domain = "example.com"
}
```

### Subset of Regions

Override `buckets` to deploy only to specific regions. Exactly one entry must set `is_main = true`.

```hcl
module "mrap_static_site" {
  source  = "edstuurman/mrap-static-site/aws"
  version = "~> 1.0"

  environment_domain = "example.com"

  buckets = [
    {
      region  = "us-east-1"
      is_main = true
    },
    {
      region = "eu-west-1"
    },
    {
      region = "ap-northeast-1"
    },
  ]
}
```

### Custom 404 Page

Configure CloudFront custom error responses (such as serving `/404.html` on S3 `404` or `403` responses):

```hcl
module "mrap_static_site" {
  source  = "edstuurman/mrap-static-site/aws"
  version = "~> 1.0"

  environment_domain = "example.com"

  custom_error_responses = [
    {
      error_code            = 404
      response_code         = 404
      response_page_path    = "/404.html"
      error_caching_min_ttl = 60
    }
  ]
}
```

### Apex-Only / Disabling `www` Redirect

Serve the site directly on the apex domain without provisioning `www.example.com` or redirecting apex traffic:

```hcl
module "mrap_static_site" {
  source  = "edstuurman/mrap-static-site/aws"
  version = "~> 1.0"

  environment_domain   = "example.com"
  cloudfront_aliases   = ["example.com"]
  redirect_apex_to_www = false
}
```

See [`examples/minimal`](./examples/minimal) and [`examples/complete`](./examples/complete) for full runnable configurations.

## Provisioning Notes

- **Initial Apply Duration (~20–30 Minutes)**: While provisioning is fully automated, the first greenfield `terraform apply` typically takes **20–30 minutes** because AWS must provision and globally propagate the S3 Multi-Region Access Point routing control plane, complete ACM DNS validation, and deploy the CloudFront distribution across global edge locations. Subsequent site content uploads to `primary_upload_bucket` complete in seconds.
- **S3 MRAP Bucket Membership Immutability**: AWS S3 Multi-Region Access Points fix their underlying bucket membership at creation time—buckets cannot be added to or removed from an existing MRAP in place without recreating the MRAP resource. Decide on your active `buckets` region list before the initial `terraform apply`.
- **Route 53 Hosted Zone Prerequisite**: Pass `environment_domain` as a naked root domain without `https://` or `www.` (for example, `example.com`). A public Route 53 Hosted Zone matching `environment_domain` (or specified explicitly via `route53_zone_id`) must already exist, with your registrar's `NS` records pointing to Route 53 so automated ACM DNS validation succeeds.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| :--- | :--- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | `>= 1.10.0` |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | `~> 6.0` |

## Providers

| Name | Version |
| :--- | :--- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | `~> 6.0` |

## Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :---: |
| <a name="input_environment_domain"></a> [environment\_domain](#input\_environment\_domain) | Naked apex domain name for the static site (e.g. `example.com`). Must match an existing public Route 53 Hosted Zone unless `route53_zone_id` is provided. | `string` | n/a | yes |
| <a name="input_environment_domain_slug"></a> [environment\_domain\_slug](#input\_environment\_domain\_slug) | Optional resource naming slug prefix. Defaults to `environment_domain` with dots replaced by hyphens (e.g. `example-com`). | `string` | `null` | no |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Optional AWS Account ID override. When `null`, automatically discovered via `aws_caller_identity`. | `string` | `null` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Optional Route 53 Hosted Zone ID override. When `null`, looked up automatically using `environment_domain`. | `string` | `null` | no |
| <a name="input_cloudfront_aliases"></a> [cloudfront\_aliases](#input\_cloudfront\_aliases) | Alternate domain names (CNAMEs) attached to the CloudFront distribution and Route 53 alias records. Defaults to `["www.${environment_domain}", environment_domain]`. | `list(string)` | `null` | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | CloudFront distribution price class (`PriceClass_100`, `PriceClass_200`, or `PriceClass_All`). | `string` | `"PriceClass_200"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Object CloudFront requests from the origin when a viewer requests the root URL. | `string` | `"index.html"` | no |
| <a name="input_redirect_apex_to_www"></a> [redirect\_apex\_to\_www](#input\_redirect\_apex\_to\_www) | Whether the CloudFront Function issues a `301` redirect from `environment_domain` to `www.${environment_domain}`. | `bool` | `true` | no |
| <a name="input_enable_directory_index_rewrite"></a> [enable\_directory\_index\_rewrite](#input\_enable\_directory\_index\_rewrite) | Whether the CloudFront Function rewrites directory paths (e.g. `/about/` or `/about`) to `/index.html`. | `bool` | `true` | no |
| <a name="input_noncurrent_version_expiration_days"></a> [noncurrent\_version\_expiration\_days](#input\_noncurrent\_version\_expiration\_days) | Number of days after which noncurrent S3 object versions expire across all regional buckets. | `number` | `7` | no |
| <a name="input_custom_error_responses"></a> [custom\_error\_responses](#input\_custom\_error\_responses) | List of CloudFront custom error response blocks. | <pre>list(object({<br/>  error_code            = number<br/>  response_code         = optional(number)<br/>  response_page_path    = optional(string)<br/>  error_caching_min_ttl = optional(number)<br/>}))</pre> | `[]` | no |
| <a name="input_buckets"></a> [buckets](#input\_buckets) | List of regional S3 buckets included in the Multi-Region Access Point. Exactly one entry must have `is_main = true`. | <pre>list(object({<br/>  region   = string<br/>  is_main  = optional(bool, false)<br/>  priority = optional(number)<br/>}))</pre> | 17 default-enabled AWS regions with `ap-northeast-1` as `is_main = true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags applied to all taggable AWS resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| :--- | :--- |
| <a name="output_primary_upload_bucket"></a> [primary\_upload\_bucket](#output\_primary\_upload\_bucket) | Name of the primary S3 bucket (`is_main = true`) where static site artifacts should be uploaded. |
| <a name="output_primary_upload_region"></a> [primary\_upload\_region](#output\_primary\_upload\_region) | AWS region of the primary S3 upload bucket. |
| <a name="output_active_bucket_regions"></a> [active\_bucket\_regions](#output\_active\_bucket\_regions) | List of all active AWS regions provisioned in the S3 Multi-Region Access Point. |
| <a name="output_bucket_names"></a> [bucket\_names](#output\_bucket\_names) | Map of AWS region to provisioned S3 bucket name. |
| <a name="output_mrap_alias"></a> [mrap\_alias](#output\_mrap\_alias) | S3 Multi-Region Access Point alias identifier. |
| <a name="output_mrap_domain_name"></a> [mrap\_domain\_name](#output\_mrap\_domain\_name) | Global S3 Multi-Region Access Point endpoint domain name used as the CloudFront origin. |
| <a name="output_mrap_arn"></a> [mrap\_arn](#output\_mrap\_arn) | ARN of the S3 Multi-Region Access Point. |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | CloudFront distribution ID (used for cache invalidations on deployment). |
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | ARN of the CloudFront distribution. |
| <a name="output_cloudfront_domain_name"></a> [cloudfront\_domain\_name](#output\_cloudfront\_domain\_name) | CloudFront distribution domain name (`*.cloudfront.net`). |
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | ARN of the validated `us-east-1` ACM certificate attached to CloudFront. |
| <a name="output_site_urls"></a> [site\_urls](#output\_site\_urls) | List of HTTPS URLs configured for the static site. |
<!-- END_TF_DOCS -->

## Author & Related Projects

- **Author**: [Edouard Stuurman](https://www.stuurman.com/)
- **Related Project**: [The Navigator](https://astro.build/themes/details/the-navigator/) — Astro static site theme originally built to pair with this multi-region S3 MRAP + CloudFront SigV4a architecture.

## License

MIT License — see [LICENSE](./LICENSE) for details.
