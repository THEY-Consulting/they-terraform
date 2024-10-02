terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.25" # introduced archive_policy https://github.com/hashicorp/terraform-provider-aws/issues/34150
    }
  }
}
