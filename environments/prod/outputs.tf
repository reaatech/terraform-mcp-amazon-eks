output "cluster_name" {
  value = module.mcp_eks.cluster_name
}

output "cluster_endpoint" {
  value = module.mcp_eks.cluster_endpoint
}

output "sqs_queue_urls" {
  value = module.mcp_eks.sqs_queue_urls
}

output "elasticache_endpoint" {
  value = module.mcp_eks.elasticache_endpoint
}

output "monitoring_dashboard_name" {
  value = module.mcp_eks.monitoring_dashboard_name
}
