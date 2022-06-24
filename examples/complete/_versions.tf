terraform {
  required_version = ">= 1.1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.12.1"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.8.0"
    }
  }
}
