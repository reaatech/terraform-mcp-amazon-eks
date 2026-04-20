# Observability

## Capability
Deploy comprehensive observability for MCP servers on EKS with CloudWatch metrics, dashboards, X-Ray distributed tracing, and alert policies for SLO monitoring.

## Components

### CloudWatch Dashboard
The monitoring module creates a dashboard with:
- **EKS metrics** — Cluster CPU and memory utilization
- **SQS metrics** — Queue depth across all queues (configurable queue names)
- **ElastiCache metrics** — Memory usage percentage
- **Custom widgets** — Active consumers, pod restart counts

```hcl
module "monitoring" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/monitoring"

  cluster_name = "mcp-prod"
  namespace    = "mcp"
  alert_email  = "alerts@example.com"

  enable_alarms = true
  xray_enabled  = true

  sqs_queue_names = ["mcp-tasks", "mcp-results", "mcp-events"]
}
```

### Alert Policies
| Alert | Metric | Threshold | Severity |
|-------|--------|-----------|----------|
| High CPU | EKS CPU utilization | > 80% for 2 periods | Warning |
| High Memory | EKS memory utilization | > 80% for 2 periods | Warning |
| High Queue Depth | SQS ApproximateNumberOfMessagesVisible | > 100 for 2 periods | Warning |

### X-Ray Tracing
- Sampling rule: 5% fixed rate (configurable)
- Traces all MCP requests end-to-end
- Annotations for MCP method, tool name, session ID

## Terraform Resources
| Resource | Purpose | Key Configuration |
|----------|---------|-------------------|
| `aws_cloudwatch_dashboard` | Metrics dashboard | EKS, SQS, ElastiCache widgets |
| `aws_cloudwatch_metric_alarm` | Alert policies | CPU, memory, queue depth |
| `aws_sns_topic` | Alert notifications | Email subscription |
| `aws_xray_sampling_rule` | Trace sampling | 5% fixed rate |

## Metrics Reference
| Metric | Namespace | Dimensions | Description |
|--------|-----------|------------|-------------|
| `cpu_utilization` | AWS/EKS | ClusterName | Cluster CPU usage |
| `memory_utilization` | AWS/EKS | ClusterName | Cluster memory usage |
| `ApproximateNumberOfMessagesVisible` | AWS/SQS | QueueName | Queue depth |
| `DatabaseMemoryUsagePercentage` | AWS/ElastiCache | CacheClusterId | Redis memory usage |

## Debug Commands
```bash
# Get dashboard URL
terraform output -raw monitoring_dashboard_url

# Check pod logs
kubectl logs -n mcp deployment/mcp-server --tail=100

# Check pod restart count
kubectl get pods -n mcp -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount

# Check SQS queue depth
aws sqs get-queue-attributes \
  --queue-url "$(terraform output -raw sqs_queue_urls | jq -r '.mcp-tasks')" \
  --attribute-names ApproximateNumberOfMessages
```

## Error Handling
- **No dashboard data**: Verify CloudWatch metrics are being emitted (check pod logs for AWS SDK errors)
- **X-Ray traces missing**: Ensure pod has `xray:PutTraceSegments` permission via IRSA
- **Alerts not firing**: Check SNS topic subscription is confirmed (check email)
- **Queue depth always 0**: Verify KEDA is processing messages (check ScaledObject status)

## References
- [CloudWatch Dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboard.html)
- [X-Ray Sampling](https://docs.aws.amazon.com/xray/latest/devguide/xray-console-sampling.html)
- [CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
