# EKS Hot-Pod Pattern

## Capability
Deploy MCP servers on Amazon EKS with the FaaS-runtime-style hot-pod pattern for sub-100ms response times using KEDA-based scaling.

## Terraform Resources
| Resource | Purpose | Key Configuration |
|----------|---------|-------------------|
| `aws_eks_cluster` | EKS cluster | `vpc_config`, `enabled_cluster_log_types`, `encryption_config` |
| `aws_eks_node_group` | Managed node groups | `scaling_config`, `instance_types` |
| `kubernetes_deployment` | MCP server deployment | `replicas`, `resources`, probes |
| `kubernetes_manifest` (KEDA) | ScaledObject for auto-scaling | `minReplicaCount`, `maxReplicaCount`, `triggers` (apiVersion: keda.sh/v1alpha1) |

## Usage Examples

### Basic Hot-Pod Deployment
```hcl
module "keda" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/mcp-service"
  
  cluster_name    = module.mcp_eks.cluster_name
  namespace       = "mcp"
  deployment_name = "mcp-server"
  
  min_replicas     = 0
  max_replicas     = 20
  warm_pool_size   = 2
  
  scale_up_threshold = 5
  scale_down_delay   = 300
  
  sqs_queue_url = module.sqs.queue_urls["mcp-tasks"]
}
```

### Production Configuration
```hcl
module "keda" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/mcp-service"
  
  min_replicas     = 1   # Always keep 1 pod warm
  max_replicas     = 50
  warm_pool_size   = 5   # Keep 5 pods pre-warmed
  
  scale_up_threshold = 10   # Scale up when 10 messages in queue
  scale_down_delay   = 600  # Wait 10 minutes before scaling down
}
```

## Error Handling
- **Pod crash loop**: Check resource limits and IRSA permissions
- **Slow scale-up**: Decrease `scale_up_threshold` or increase `warm_pool_size`
- **High latency**: Increase warm pool or optimize application code

## Security Considerations
- Use IRSA for pod-level IAM roles
- Never use node-level IAM permissions
- Keep pods in private subnets
- Use Secrets Manager for all credentials
