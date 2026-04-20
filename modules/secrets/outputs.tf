output "secret_arns" {
  description = "Map of secret names to their ARNs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_names" {
  description = "Map of secret names to their names"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}
