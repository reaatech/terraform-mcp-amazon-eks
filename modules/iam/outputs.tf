output "role_arns" {
  description = "Map of service account names to their IAM role ARNs"
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Map of service account names to their IAM role names"
  value       = { for k, v in aws_iam_role.this : k => v.name }
}
