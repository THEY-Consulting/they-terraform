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
    key            = "openid-github/terraform.tfstate"
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

provider "azurerm" {
  features {}

  skip_provider_registration = true # We don't have enough permissions to register all providers
  tenant_id                  = var.tenant_id
}

variable "tenant_id" {
  description = "Use specific azure tenant ID."
  type        = string
  default     = null
}
