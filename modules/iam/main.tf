# IAM roles for service accounts (IRSA)
resource "aws_iam_role" "this" {
  for_each = var.service_accounts

  name = "${var.cluster_name}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.key}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Attach managed policies to roles
resource "aws_iam_role_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for sa_name, sa in var.service_accounts : [
        for policy_arn in sa.policies : {
          key        = "${sa_name}-${replace(replace(policy_arn, ":", "_"), "/", "_")}"
          sa_name    = sa_name
          policy_arn = policy_arn
        }
      ]
    ]) :
    pair.key => {
      sa_name    = pair.sa_name
      policy_arn = pair.policy_arn
    }
  }

  role       = aws_iam_role.this[each.value.sa_name].name
  policy_arn = each.value.policy_arn
}

# Inline policies for roles
resource "aws_iam_role_policy" "this" {
  for_each = {
    for pair in flatten([
      for sa_name, sa in var.service_accounts : [
        for policy_name, policy_doc in sa.inline_policies : {
          key         = "${sa_name}-${policy_name}"
          sa_name     = sa_name
          policy_name = policy_name
          policy_doc  = policy_doc
        }
      ]
    ]) :
    pair.key => {
      sa_name     = pair.sa_name
      policy_name = pair.policy_name
      policy_doc  = pair.policy_doc
    }
  }

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.sa_name].id
  policy = each.value.policy_doc
}
