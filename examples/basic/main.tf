terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "mcp_eks" {
  source = "../.."

  region           = var.region
  cluster_name     = var.cluster_name
  subnet_ids       = var.subnet_ids
  mcp_server_image = var.mcp_server_image
  alert_email      = var.alert_email
  environment      = "basic-example"
}
