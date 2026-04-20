output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service.this.metadata[0].name
}

output "service_port" {
  description = "Port exposed by the Kubernetes service"
  value       = kubernetes_service.this.spec[0].port[0].port
}

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.this.metadata[0].name
}

output "namespace" {
  description = "Namespace of the deployment"
  value       = var.namespace
}

output "service_account_name" {
  description = "Service account bound to the deployment"
  value       = kubernetes_service_account.this.metadata[0].name
}

output "warm_pool_size" {
  description = "Configured warm pool size"
  value       = var.warm_pool_size
}
