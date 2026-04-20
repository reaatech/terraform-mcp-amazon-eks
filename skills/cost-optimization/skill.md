# Cost Optimization

## Capability
Deploy MCP servers on EKS with cost optimization strategies: scale-to-zero, right-sizing, spot instances, warm pool tuning, and budget alerts.

## Cost Components

| Component | Pricing | Dev (Monthly) | Prod (Monthly) |
|-----------|---------|---------------|----------------|
| EKS | $0.10/hour | $72 | $72 |
| EC2 (t3.medium) | $0.0416/hour | $60 (2 nodes) | $216 (6 nodes) |
| EC2 (t3.large) | $0.0832/hour | — | $432 (6 nodes) |
| ElastiCache (cache.t3.micro) | $0.017/hour | $12 | $12 |
| ElastiCache (cache.t3.medium) | $0.068/hour | — | $49 |
| SQS | $0.40/million requests | ~$1 | ~$4 |
| Secrets Manager | $0.40/secret/month | $0.40 | $2 |
| CloudWatch | Usage-based | ~$5 | ~$10 |
| X-Ray | $5/100k traces | ~$2 | ~$5 |

**Total: Dev ~$115/month, Prod ~$800/month**

## Optimization Strategies

### 1. Scale-to-Zero with KEDA
```hcl
module "keda" {
  min_replicas     = 0   # Scale to zero when idle
  max_replicas     = 20
  warm_pool_size   = 1   # Keep 1 pod warm during business hours

  scale_up_threshold = 5   # Scale up when 5 messages queue
  scale_down_delay   = 300 # Wait 5 minutes before scaling down
}
```

### 2. Right-Size Node Groups
| Workload | Node Type | Min/Max | Use Case |
|----------|-----------|---------|----------|
| Dev | t3.small | 1/3 | Development, testing |
| Dev | t3.medium | 2/5 | Integration testing |
| Medium | t3.medium | 2/5 | Small production |
| Medium | t3.large | 3/10 | Standard production |
| High traffic | t3.large | 3/20 | High-traffic production |

### 3. Spot Instances for Non-Critical Workloads
```hcl
node_groups = {
  spot = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 5
    capacity_type  = "SPOT"  # 70% cheaper than On-Demand
  }
  on_demand = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 5
    capacity_type  = "ON_DEMAND"  # For critical pods
  }
}
```

### 4. Warm Pool Tuning
| Traffic Level | Warm Pool | Scale-Down Delay | Scale-Up Threshold |
|---------------|-----------|------------------|-------------------|
| Low | 1 | 600s (10 min) | 10 |
| Medium | 2 | 300s (5 min) | 5 |
| High | 5 | 180s (3 min) | 3 |

### 5. ElastiCache Right-Sizing
| Workload | Node Type | Nodes | Monthly Cost |
|----------|-----------|-------|--------------|
| Dev | cache.t3.micro | 1 | $12 |
| Medium | cache.t3.small | 1 | $25 |
| Production | cache.t3.medium | 2 (Multi-AZ) | $98 |

### 6. Budget Alerts
```hcl
resource "aws_budgets_budget" "mcp" {
  name              = "mcp-budget"
  budget_type       = "COST"
  limit_amount      = "500"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["billing@example.com"]
  }
}
```

## Cost Monitoring
```bash
# Check current month spend
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "1 month ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# Check SQS request count (for cost estimation)
aws sqs get-queue-attributes \
  --queue-url <queue-url> \
  --attribute-names ApproximateNumberOfMessagesDeleted
```

## Error Handling
- **Pods stuck pending**: Spot capacity unavailable — add On-Demand fallback node group
- **High latency after scale-up**: Warm pool too small — increase `warm_pool_size`
- **Budget alert firing**: Check for runaway scaling — verify `max_replicas` is bounded
- **SQS costs higher than expected**: Check for message processing loops — verify `maxReceiveCount`

## References
- [AWS Cost Explorer](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-consolidated-analysis.html)
- [KEDA Cost Optimization](https://keda.sh/docs/2.12/concepts/scaling-deployments/)
- [EC2 Spot Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html)
