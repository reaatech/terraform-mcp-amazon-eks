module "mcp_eks" {
  source = "../.."

  region                                 = var.region
  cluster_name                           = var.cluster_name
  environment                            = "dev"
  subnet_ids                             = var.subnet_ids
  mcp_server_image                       = var.mcp_server_image
  alert_email                            = var.alert_email
  endpoint_public_access                 = true
  enable_keda                            = true
  enable_keda_scaling                    = true
  warm_pool_size                         = 1
  min_replicas                           = 0
  max_replicas                           = 10
  elasticache_transit_encryption_enabled = false

  env_vars = {
    LOG_LEVEL = "DEBUG"
  }
}
