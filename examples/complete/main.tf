provider "aws" {
  region = "ap-northeast-1"
}

module "mrap_static_site" {
  source = "../.."

  environment_domain                 = "example.com"
  cloudfront_price_class             = "PriceClass_200"
  default_root_object                = "index.html"
  redirect_apex_to_www               = true
  enable_directory_index_rewrite     = true
  noncurrent_version_expiration_days = 14

  # Uses the module's default 17-region active-active S3 + MRAP mesh.
  custom_error_responses = [
    {
      error_code            = 404
      response_code         = 404
      response_page_path    = "/404.html"
      error_caching_min_ttl = 60
    },
  ]

  tags = {
    Project   = "example.com"
    ManagedBy = "Terraform"
  }
}
