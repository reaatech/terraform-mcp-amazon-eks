# AWS Secrets Manager Secrets
resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = each.value.secret_id
  description             = each.value.description
  kms_key_id              = coalesce(each.value.kms_key_id, "alias/aws/secretsmanager")
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, {
    Name = each.value.secret_id
  })
}

# Secret Versions (optional - only if values are provided)
resource "aws_secretsmanager_secret_version" "this" {
  for_each = { for k, v in var.secret_values : k => v if contains(keys(var.secrets), k) }

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value
}

# Secret Policies for Access Control (per secret)
resource "aws_secretsmanager_secret_policy" "this" {
  for_each = length(var.access_roles) > 0 ? aws_secretsmanager_secret.this : {}

  secret_arn = each.value.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.access_roles
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}
