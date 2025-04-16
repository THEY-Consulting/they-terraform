terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.77"
    }
  }

  backend "s3" {
    bucket         = "they-terraform-examples-tfstate"
    encrypt        = true
    dynamodb_table = "they-terraform-examples-tfstate-lock"
    key            = "lambda-with-custom-headers/terraform.tfstate"
    region         = "eu-central-1"
  }

  required_version = "1.6.4"
}

// default provider that is used when no other provider
// is specified explicitly
provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Project   = "they-terraform-examples"
      CreatedBy = "terraform"
    }
  }
}
