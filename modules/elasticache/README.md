# ElastiCache Module

Provision a Redis replication group suitable for MCP session state, with optional Multi-AZ failover, TLS, AUTH, and snapshot retention.

## Usage

```hcl
module "elasticache" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/elasticache"

  cluster_id         = "mcp-prod-redis"
  node_type          = "cache.t3.medium"
  num_cache_nodes    = 2
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.eks.cluster_security_group_id]

  transit_encryption_enabled = true
  multi_az_enabled           = true
  auth_token                 = var.redis_auth_token
}
```

## Notes

- the module uses `aws_elasticache_replication_group`, not a single-node cache cluster resource
- `num_cache_nodes > 1` enables primary/replica topology
- `multi_az_enabled = true` turns on automatic failover
