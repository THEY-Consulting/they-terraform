terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
  }

  backend "s3" {
    bucket         = "they-terraform-examples-tfstate"
    encrypt        = true
    dynamodb_table = "they-terraform-examples-tfstate-lock"
    key            = "frontdoor_with_external_domain/terraform.tfstate"
    region         = "eu-central-1"
  }

  required_version = ">= 1.6, < 2.0"
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "The subscription ID to use for the Azure provider"
  type        = string
}
