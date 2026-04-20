# terraform-mcp-aws-eks

Opinionated Terraform module for deploying an MCP workload to Amazon EKS with Redis, SQS, IRSA, CloudWatch monitoring, and KEDA-based scale-from-queue behavior. The root module is the drop-in path; the submodules are available when you want to compose pieces selectively.

## Quick Start

```hcl
module "mcp_eks" {
  source           = "github.com/reaatech/terraform-mcp-aws-eks"
  cluster_name     = "my-cluster"
  mcp_server_image = "my-registry/my-mcp-server:latest"
}
```

This root module:

- creates an EKS cluster and managed node group
- installs KEDA by default through Helm
- deploys one MCP workload with IRSA, probes, HPA, and an SQS-backed `ScaledObject`
- provisions ElastiCache Redis for session state
- provisions SQS task and result queues plus a dead-letter queue
- creates Secrets Manager secrets and grants the workload least-privilege read access
- creates a CloudWatch dashboard, SNS alert topic, and baseline alarms

If you already manage KEDA yourself, set `enable_keda = false`. The module will skip the Helm install but still create KEDA scaling resources when `enable_keda_scaling = true`.

## Root Module Behavior

- `subnet_ids = null` falls back to all subnets in the selected VPC, or the default VPC if `vpc_id` is also unset
- `endpoint_public_access = true` by default so the drop-in path can complete from a normal operator workstation
- a default Secrets Manager secret named `${cluster_name}-api-key` is created unless `create_api_key_secret = false`
- the workload receives secret ARNs as environment variables; your application should fetch secret values from Secrets Manager using AWS SDK calls or you can add your own External Secrets / CSI integration

## Common Patterns

### Drop-in module

```hcl
module "mcp_eks" {
  source           = "github.com/reaatech/terraform-mcp-aws-eks"
  cluster_name     = "my-cluster"
  mcp_server_image = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-mcp@sha256:abc123"

  env_vars = {
    LOG_LEVEL = "INFO"
  }
}
```

### Existing KEDA installation

```hcl
module "mcp_eks" {
  source           = "github.com/reaatech/terraform-mcp-aws-eks"
  cluster_name     = "my-cluster"
  mcp_server_image = "my-registry/my-mcp-server:latest"

  enable_keda = false
}
```

### Private production deployment

```hcl
module "mcp_eks" {
  source           = "github.com/reaatech/terraform-mcp-aws-eks"
  cluster_name     = "mcp-prod"
  subnet_ids       = var.private_subnet_ids
  mcp_server_image = var.mcp_server_image

  endpoint_public_access       = false
  elasticache_num_nodes        = 2
  elasticache_multi_az_enabled = true
  elasticache_auth_token       = var.redis_auth_token
  min_replicas                 = 1
  warm_pool_size               = 3
}
```

## Module Layout

- `.`: drop-in wrapper that wires the EKS, Redis, SQS, secrets, monitoring, KEDA install, and MCP workload together
- `modules/eks`: managed EKS cluster and OIDC provider
- `modules/keda`: KEDA Helm installation
- `modules/mcp-service`: Kubernetes deployment, service account, HPA, and KEDA scaling resources
- `modules/elasticache`: Redis replication group
- `modules/sqs`: SQS queues and dead-letter queue
- `modules/iam`: IRSA roles and inline policies
- `modules/secrets`: Secrets Manager secrets and access policies
- `modules/monitoring`: CloudWatch dashboard, SNS topic, alarms, and X-Ray sampling
- `environments/*`: reference root-module stacks
- `examples/*`: example entry points showing common usage patterns

## Examples

- `examples/basic`: simplest root-module deployment
- `examples/multi-service`: root-module deployment with extra queues for orchestrator-style traffic patterns
- `examples/vpc-only`: private-endpoint deployment for locked-down VPCs
- `environments/dev`: development defaults with public API access and scale-to-zero
- `environments/prod`: production defaults with private API access and HA Redis

## Notes

- Terraform >= 1.6 is required
- The module expects AWS credentials and the `aws` CLI to be available for EKS authentication
- KEDA installation follows the official Helm-based workflow from KEDA docs: https://keda.sh/docs/2.19/deploy/
- For the AWS SQS scaler, the module uses KEDA `TriggerAuthentication` with pod identity, following the official KEDA SQS scaler guidance: https://keda.sh/docs/2.19/scalers/aws-sqs/

## References

- [AGENTS.md](AGENTS.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [SECURITY.md](SECURITY.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
