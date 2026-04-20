output "release_name" {
  description = "Helm release name for KEDA"
  value       = helm_release.this.name
}

output "namespace" {
  description = "Namespace where KEDA is installed"
  value       = helm_release.this.namespace
}

output "status" {
  description = "Status of the KEDA Helm release"
  value       = helm_release.this.status
}
