terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.58"
    }
  }

  backend "s3" {
    bucket         = "they-terraform-examples-tfstate"
    encrypt        = true
    dynamodb_table = "they-terraform-examples-tfstate-lock"
    key            = "function-app-with-diagnostics/terraform.tfstate"
    region         = "eu-central-1"
  }

  required_version = "1.6.4"
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "none" # In case we don't have enough permissions to register all providers

  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "The subscription ID to use for the Azure provider"
  type        = string
  default     = null
}
