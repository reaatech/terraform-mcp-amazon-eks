output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded EKS cluster certificate authority data"
  value       = module.eks.cluster_ca_certificate
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "sqs_queue_urls" {
  description = "SQS queue URLs keyed by queue name"
  value       = module.sqs.queue_urls
}

output "sqs_queue_arns" {
  description = "SQS queue ARNs keyed by queue name"
  value       = module.sqs.queue_arns
}

output "elasticache_endpoint" {
  description = "Primary ElastiCache endpoint in host:port form"
  value       = module.elasticache.cluster_endpoint
}

output "elasticache_reader_endpoint" {
  description = "Reader endpoint for the ElastiCache replication group"
  value       = module.elasticache.reader_endpoint_address
}

output "service_name" {
  description = "Kubernetes Service name for the MCP workload"
  value       = module.mcp_service.service_name
}

output "service_namespace" {
  description = "Kubernetes namespace for the MCP workload"
  value       = module.mcp_service.namespace
}

output "service_account_role_arn" {
  description = "IAM role ARN assigned to the MCP workload service account"
  value       = module.iam.role_arns[var.service_account_name]
}

output "secret_arns" {
  description = "Secrets Manager secret ARNs keyed by logical secret name"
  value       = module.secrets.secret_arns
}

output "monitoring_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.monitoring.dashboard_name
}

output "monitoring_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "alarm_names" {
  description = "CloudWatch alarm names created by the monitoring module"
  value       = module.monitoring.alarm_names
}

output "keda_release_status" {
  description = "Status of the optional KEDA Helm release"
  value       = try(module.keda[0].status, null)
}
