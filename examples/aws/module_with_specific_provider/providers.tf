terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.26.0"
    }
  }

  required_version = "1.6.4"
}

// default provider that is used when no other provider
// is specified explicitly
provider "aws" {
  region = "eu-west-1"
  alias  = "specific"

  default_tags {
    tags = {
      Project   = "they-terraform-examples"
      CreatedBy = "terraform"
    }
  }
}
