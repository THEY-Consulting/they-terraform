terraform {
  required_providers {
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.0.7"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.81"
    }
  }

  backend "s3" {
    bucket         = "they-terraform-examples-tfstate"
    encrypt        = true
    dynamodb_table = "they-terraform-examples-tfstate-lock"
    key            = "container-apps-custom-domains/terraform.tfstate"
    region         = "eu-central-1"
  }

  required_version = "1.6.4"
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
