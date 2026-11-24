provider "aws" {
  region = "ap-northeast-1"
}

module "mrap_static_site" {
  source = "../.."

  environment_domain = "example.com"

  buckets = [
    { region = "ap-northeast-1", is_main = true },
    { region = "us-east-1" },
    { region = "eu-west-1" },
  ]
}
