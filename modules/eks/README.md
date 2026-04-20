# EKS Module

EKS cluster with managed node groups, OIDC provider for IRSA, and VPC CNI/CoreDNS/kube-proxy addons.

## Usage

```hcl
module "eks" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/eks"

  cluster_name = "mcp-prod"
  subnet_ids   = var.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["t3.large"]
      min_size       = 3
      max_size       = 10
    }
  }

  kubernetes_version = "1.30"

  tags = {
    Environment = "prod"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| aws | >= 5.0, < 6.0 |
| tls | >= 4.0, < 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | EKS cluster name | `string` | n/a | yes |
| subnet_ids | Private subnet IDs | `list(string)` | n/a | yes |
| node_groups | Node group definitions | `map(object)` | `{}` | no |
| kubernetes_version | Kubernetes version | `string` | `"1.30"` | no |
| cluster_security_group_ids | Additional security groups | `list(string)` | `[]` | no |
| cluster_log_types | Control plane log types | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| enable_encryption | Enable KMS envelope encryption for secrets | `bool` | `true` | no |
| kms_key_id | KMS key ARN for encryption (null to auto-create) | `string` | `null` | no |
| tags | Tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | EKS API endpoint |
| cluster_ca_certificate | Cluster CA certificate (base64) |
| cluster_name | Cluster name |
| cluster_security_group_id | Cluster security group ID |
| oidc_provider_arn | OIDC provider ARN for IRSA |
| oidc_provider_url | OIDC provider URL |
| node_role_arn | Worker node IAM role ARN |
| cluster_version | Kubernetes version |

## Security

- EKS private endpoint only (no public access)
- encryption_config with secrets resource for etcd encryption
- OIDC provider for IRSA (pod-level IAM)
- Managed node groups with auto-scaling
