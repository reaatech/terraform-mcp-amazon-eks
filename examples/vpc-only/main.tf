terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.43"
    }
  }
}

provider "aws" {
  region = var.region
}

module "mcp_eks" {
  source = "../.."

  region                       = var.region
  cluster_name                 = var.cluster_name
  subnet_ids                   = var.subnet_ids
  mcp_server_image             = var.mcp_server_image
  alert_email                  = var.alert_email
  environment                  = "vpc-only-example"
  endpoint_public_access       = false
  elasticache_num_nodes        = 2
  elasticache_multi_az_enabled = true
  min_replicas                 = 1
  warm_pool_size               = 2
  max_replicas                 = 20
  scale_up_threshold           = 10
}
