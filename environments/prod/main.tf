module "mcp_eks" {
  source = "../.."

  region                       = var.region
  cluster_name                 = var.cluster_name
  environment                  = "prod"
  subnet_ids                   = var.subnet_ids
  mcp_server_image             = var.mcp_server_image
  alert_email                  = var.alert_email
  endpoint_public_access       = false
  elasticache_num_nodes        = 2
  elasticache_node_type        = "cache.t3.medium"
  elasticache_multi_az_enabled = true
  elasticache_auth_token       = var.redis_auth_token
  min_replicas                 = 1
  max_replicas                 = 20
  warm_pool_size               = 3
  scale_up_threshold           = 10
  scale_down_delay             = 600

  node_groups = {
    general = {
      instance_types = ["t3.large"]
      min_size       = 3
      max_size       = 10
    }
  }

  env_vars = {
    LOG_LEVEL = "INFO"
  }
}
