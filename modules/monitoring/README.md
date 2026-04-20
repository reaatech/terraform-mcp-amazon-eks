# Monitoring Module

CloudWatch dashboard, SNS notifications, CloudWatch alarms, and X-Ray sampling for an MCP deployment.

## Usage

```hcl
module "monitoring" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/monitoring"

  cluster_name           = "mcp-prod"
  elasticache_cluster_id = "mcp-prod-redis"
  sqs_queue_names        = ["mcp-prod-tasks", "mcp-prod-results"]
  alert_email            = "alerts@example.com"
}
```

## What It Creates

- CloudWatch dashboard for EKS, SQS, and ElastiCache visibility
- optional SNS topic and email subscription for alarm notifications
- SQS queue depth alarms
- ElastiCache CPU and memory alarms
- X-Ray sampling rule
