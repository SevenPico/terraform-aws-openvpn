terraform {
  required_version = ">= 1.1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.12.1"
    }
    archive = {
      source = "hashicorp/archive"
      version = ">= 2.2.0"
    }
  }
}
