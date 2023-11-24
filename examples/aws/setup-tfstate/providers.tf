terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.26.0"
    }
  }

  backend "s3" {
    bucket         = "they-terraform-examples-tfstate"
    encrypt        = true
    dynamodb_table = "they-terraform-examples-tfstate-lock"
    key            = "setup-tfstate-example/terraform.tfstate"
    region         = "eu-central-1"
  }

  required_version = "1.6.4"
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Project   = "they-terraform-examples"
      CreatedBy = "terraform"
    }
  }
}
