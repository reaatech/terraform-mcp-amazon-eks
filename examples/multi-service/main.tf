terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.44"
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
  mcp_server_image             = var.orchestrator_image
  alert_email                  = var.alert_email
  environment                  = "multi-service-example"
  deployment_name              = "mcp-orchestrator"
  service_account_name         = "mcp-orchestrator"
  elasticache_num_nodes        = 2
  elasticache_multi_az_enabled = true
  min_replicas                 = 1
  warm_pool_size               = 2
  max_replicas                 = 10
  scale_up_threshold           = 10
  sqs_queues = {
    "${var.cluster_name}-tasks" = {
      visibility_timeout_seconds = 60
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 20
    }
    "${var.cluster_name}-results" = {
      visibility_timeout_seconds = 120
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 20
    }
    "${var.cluster_name}-events" = {
      visibility_timeout_seconds = 30
      message_retention_seconds  = 345600
      receive_wait_time_seconds  = 20
    }
  }
}
