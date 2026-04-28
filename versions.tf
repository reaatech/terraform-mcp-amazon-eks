terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.43"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0, < 3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 3.2"
    }
  }
}
