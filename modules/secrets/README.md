# Secrets Module

AWS Secrets Manager for API keys and credentials with KMS encryption and IRSA-based access control.

## Usage

```hcl
module "secrets" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/secrets"

  secrets = {
    api-key = {
      secret_id   = "mcp-prod-api-key"
      description = "API key for MCP server"
    }
  }

  access_roles = [module.iam.role_arns["mcp-server"]]
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
| secrets | Secret definitions | `map(object)` | n/a | yes |
| secret_values | Secret values (optional) | `map(string)` | `{}` | no |
| access_roles | IAM role ARNs with access | `list(string)` | `[]` | no |
| recovery_window_in_days | Days before deletion | `number` | `7` | no |
| tags | Tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arns | Map of secret names to ARNs |
| secret_names | Map of secret names to names |

## Security

- KMS encryption (default: `alias/aws/secretsmanager`)
- Per-secret access policies for IRSA roles
- Optional secret value injection (use with caution — values appear in state)
- Recovery window for accidental deletion protection
