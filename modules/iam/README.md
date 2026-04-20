# IAM Module

IRSA (IAM Roles for Service Accounts) configuration with OIDC provider trust policies for pod-level IAM.

## Usage

```hcl
module "iam" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/iam"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  service_accounts = {
    mcp-server = {
      namespace = "mcp"
      policies  = [
        "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
        "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
      ]
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| aws | >= 5.0, < 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | EKS cluster name | `string` | n/a | yes |
| oidc_provider_arn | OIDC provider ARN | `string` | n/a | yes |
| oidc_provider_url | OIDC provider URL | `string` | n/a | yes |
| service_accounts | Service account definitions | `map(object)` | n/a | yes |
| tags | Tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arns | Map of SA names to role ARNs |
| role_names | Map of SA names to role names |

## Security

- Pod-level IAM via IRSA (no node-level permissions)
- OIDC trust policy with strict namespace/service-account conditions
- Support for both managed and inline policies
- Inline policies for least-privilege access

## Best Practices

For production, use inline policies with least privilege instead of AWS managed policies:

```hcl
service_accounts = {
  mcp-server = {
    namespace = "mcp"
    policies  = []  # No managed policies
    inline_policies = {
      secrets = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = "arn:aws:secretsmanager:*:*:secret:mcp-*"
        }]
      })
    }
  }
}
```
