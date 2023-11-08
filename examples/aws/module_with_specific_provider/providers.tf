terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.11.0"
    }
  }

  required_version = "1.5.5"
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
