terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket         = "johnlien-me-tofu-state"
    key            = "www/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "johnlien-me-tofu-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

# ACM certificates for CloudFront must be in us-east-1
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile != "" ? var.aws_profile : null
}
