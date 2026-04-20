# KEDA Module

Install the KEDA operator on EKS using Helm. This module is intended to be used by the root wrapper by default, but it can also be used directly when you want to manage KEDA separately from the MCP workload resources.

## Usage

```hcl
module "keda" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/keda"

  namespace = "keda"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| helm | >= 2.0, < 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| release_name | Helm release name | `string` | `"keda"` | no |
| namespace | KEDA namespace | `string` | `"keda"` | no |
| create_namespace | Create the namespace during install | `bool` | `true` | no |
| chart_version | Optional pinned chart version | `string` | `null` | no |
| values | Raw Helm values | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| release_name | Helm release name |
| namespace | KEDA namespace |
| status | Helm release status |
