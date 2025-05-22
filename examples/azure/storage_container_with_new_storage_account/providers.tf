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
    key            = "storage-container/terraform.tfstate"
    region         = "eu-central-1"
  }

  required_version = "1.6.4"
}


provider "azurerm" {
  subscription_id = "bae375c7-4774-49cb-8b45-b69ea8f8c3ae"
  features {}

  tenant_id = var.tenant_id
}

variable "tenant_id" {
  description = "Use specific azure tenant ID."
  type        = string
  default     = null
}

variable "subscription_id" {
  description = "Use specific azure subscription ID."
  type        = string
  default     = null
}
