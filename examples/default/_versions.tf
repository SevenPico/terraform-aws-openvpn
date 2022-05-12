terraform {
  required_version = "~> 1.1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 2.2.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.1.0"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.7.2"
    }
  }

}
