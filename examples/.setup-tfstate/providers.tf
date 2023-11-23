terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.26"
    }
  }

  required_version = "1.6.4"
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project   = "they-terraform-examples"
      CreatedBy = "terraform"
    }
  }
}
