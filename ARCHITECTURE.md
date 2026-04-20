# terraform-mcp-aws-eks — Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Client Layer                                │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                  │
│  │  MCP Client │    │  agent-mesh │    │  Direct API │                  │
│  │  (Claude)   │    │  Orchestrator│   │  Consumer   │                  │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                  │
│         │                   │                   │                         │
│         └───────────────────┼───────────────────┘                         │
│                             │ HTTP/MCP                                       │
└─────────────────────────────┼─────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           EKS Cluster                                    │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    Hot-Pod Pattern                                │   │
│  │                                                                   │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐           │   │
│  │  │   Warm      │───▶│   Active    │───▶│    Scale    │           │   │
│  │  │   Pods      │    │   Pods      │    │    (KEDA)   │           │   │
│  │  │  (Idle)     │    │ (Processing)│   │             │           │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘           │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Config:                                                             │
│  - Warm pool: 1-5 pre-warmed pods                                   │
│  - Scale-to-zero: Supported via KEDA                                │
│  - Max replicas: 10-50 (configurable)                               │
│  - Node groups: Managed, auto-scaling                               │
│                                                                      │
│  Secrets: Secrets Manager → mounted as env vars                      │
│  Observability: CloudWatch + X-Ray                                   │
└─────────────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       Cross-Cutting Concerns                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│  │   ElastiCache    │  │ Secrets Manager  │  │      SQS         │       │
│  │  - Sessions      │  │  - API Keys      │  │  - Async Tasks   │       │
│  │  - State         │  │  - Tokens        │  │  - Events        │       │
│  │  - TTL           │  │  - Credentials   │  │  - DLQ           │       │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Design Principles

### 1. Hot-Pod Pattern
- Pre-warmed pods for sub-100ms response times
- KEDA-based scaling for scale-to-zero capability
- Warm pool maintained even during idle periods
- Fast scale-up on increased load

### 2. IRSA Security
- Pod-level IAM roles via IRSA
- No node-level IAM permissions
- Least privilege for each service account
- Automatic credential rotation

### 3. Observability First
- Structured JSON logging to CloudWatch
- X-Ray distributed tracing
- CloudWatch metrics and dashboards
- Alert policies for SLO monitoring

### 4. Cost Optimization
- Scale-to-zero when idle (dev)
- Right-size node groups for workload
- SQS for async processing
- Budget alerts and cost controls

### 5. Production Ready
- Managed node groups with auto-scaling
- Multi-AZ deployment
- Dead-letter queues for failure handling
- ElastiCache Multi-AZ for high availability

---

## Component Deep Dive

### EKS Cluster

The EKS cluster hosts the MCP server with the hot-pod pattern:

```hcl
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  region   = var.region
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  encryption_config {
    resources = ["secrets"]
  }
}
```

**Managed Node Groups:**

```hcl
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types

  scaling_config {
    desired_size = each.value.min_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = 1
  }
}
```

### Hot-Pod Pattern

The hot-pod pattern keeps pre-warmed pods ready for instant response:

```hcl
resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace
  }

  spec {
    replicas = var.warm_pool_size  # Keep warm pods

    template {
      spec {
        service_account_name = var.service_account_name

        container {
          name  = "mcp-server"
          image = var.image

          env {
            name  = "WARM_POOL"
            value = "true"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1024Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}
```

**KEDA Scaled Object:**

```hcl
resource "kubernetes_manifest" "scaled_object" {
  manifest = {
    apiVersion = "keda.sh/v1beta1"
    kind       = "ScaledObject"
    metadata = {
      name      = "${var.deployment_name}-scaler"
      namespace = var.namespace
    }
    spec = {
      scaleTargetRef = {
        name = var.deployment_name
      }
      minReplicaCount = var.min_replicas
      maxReplicaCount = var.max_replicas
      cooldownPeriod  = var.scale_down_delay

      advanced = {
        restoreToOriginalReplicaCount = true
      }

      triggers = [
        {
          type = "aws-sqs-queue"
          metadata = {
            queueURL      = var.sqs_queue_url
            queueLength   = var.scale_up_threshold
            awsRegion     = var.region
            identityOwner = "operator"
          }
        }
      ]
    }
  }
}
    spec = {
      scaleTargetRef = {
        name = var.deployment_name
      }
      minReplicaCount = var.min_replicas
      maxReplicaCount = var.max_replicas
      cooldownPeriod  = var.scale_down_delay

      triggers = [
        {
          type = "aws-sqs-queue"
          metadata = {
            queueURL      = var.sqs_queue_url
            queueLength   = var.scale_up_threshold
            awsRegion     = var.region
            identityOwner = "operator"
          }
        }
      ]
    }
  }
}
```

### ElastiCache for Sessions

ElastiCache provides low-latency session state:

```hcl
resource "aws_elasticache_cluster" "this" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  engine_version       = var.engine_version
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = var.security_group_ids
  parameter_group_name = aws_elasticache_parameter_group.this.name

  snapshot_retention_days = var.snapshot_retention_days
}
```

**Session Schema:**

```
Key Pattern: session:{session_id}
Value: JSON {
  "user_id": "string",
  "status": "active|completed|abandoned",
  "ttl": 1800,  // 30 minutes
  "created_at": "2026-04-15T23:00:00Z",
  "turn_history": [
    { "role": "user", "content": "...", "timestamp": "..." },
    { "role": "agent", "content": "...", "timestamp": "..." }
  ],
  "workflow_state": { ... }
}
```

### SQS for Async Tasks

SQS enables async task distribution:

```hcl
resource "aws_sqs_queue" "tasks" {
  name                       = "${var.prefix}-tasks"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention
  receive_wait_time_seconds  = 20  # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}
```

**Message Schema:**

```json
{
  "messageId": "uuid",
  "body": {
    "task_id": "uuid",
    "task_type": "process_request",
    "payload": { /* task-specific data */ },
    "callback_url": "https://orchestrator.example.com/callback"
  },
  "attributes": {
    "priority": "normal",
    "timeout_ms": "30000"
  }
}
```

---

## Security Model

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────────┐
│ Layer 1: Network                                                     │
│ - Private subnets only                                              │
│ - Security groups with minimal ingress                              │
│ - VPC endpoints for AWS services                                    │
│ - EKS private endpoint                                              │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 2: Identity                                                    │
│ - IRSA for pod-level IAM                                            │
│ - Least privilege policies                                          │
│ - No node-level IAM permissions                                     │
│ - OIDC provider for Kubernetes                                      │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 3: Secrets                                                     │
│ - Secrets Manager for all credentials                               │
│ - KMS encryption                                                    │
│ - Automatic rotation support                                        │
│ - Pod identity-based access                                         │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 4: Data                                                        │
│ - ElastiCache encryption at rest                                    │
│ - TLS in transit                                                    │
│ - PII redaction in logs                                             │
│ - Multi-AZ for high availability                                    │
└─────────────────────────────────────────────────────────────────────┘
```

### IRSA Configuration

Each MCP server pod gets a dedicated IAM role via IRSA:

```hcl
# IAM Role for MCP Server
resource "aws_iam_role" "mcp_server" {
  name = "${var.cluster_name}-mcp-server"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE:aud": "sts.amazonaws.com"
            "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE:sub": "system:serviceaccount:mcp:mcp-server"
          }
        }
      }
    ]
  })
}

# Attach least-privilege policies
resource "aws_iam_role_policy" "mcp_server" {
  role = aws_iam_role.mcp_server.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:mcp-*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "arn:aws:sqs:*:*:mcp-*"
      }
    ]
  })
}
```

---

## Data Flow

### Synchronous Request Flow

```
1. Client sends MCP request to EKS (via ALB or service mesh)
        │
2. Kubernetes routes to available pod (warm or active)
        │
3. MCP server processes request:
   - Validate authentication
   - Load session from ElastiCache (if session_id provided)
   - Execute tool or handle message
   - Update session state in ElastiCache
        │
4. Response sent to client
        │
5. CloudWatch captures structured log
        │
6. X-Ray traces the request
```

### Asynchronous Task Flow

```
1. Producer sends message to SQS queue
        │
2. KEDA detects queue depth and scales pods
        │
3. Pod receives message via SQS poll
        │
4. MCP server processes task:
   - Validate message
   - Execute task
   - Send callback to producer (if callback_url provided)
        │
5. Delete message from SQS
        │
6. On failure: message returns to queue, retry up to maxReceiveCount, then DLQ
```

### Session Management Flow

```
1. New session created:
   - Generate UUID for session_id
   - Create Redis key with TTL = 1800 seconds
   - Return session_id to client

2. Active session:
   - Lookup session by key
   - Append turn to turn_history
   - Refresh TTL
   - Update workflow_state

3. Session cleanup:
   - Redis TTL automatically expires keys
   - No manual cleanup required
```

---

## Observability

### CloudWatch Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `EKS:PodCPUUtilization` | Gauge | Pod CPU usage |
| `EKS:PodMemoryUtilization` | Gauge | Pod memory usage |
| `EKS:NodeCPUUtilization` | Gauge | Node CPU usage |
| `EKS:NodeMemoryUtilization` | Gauge | Node memory usage |
| `SQS:ApproximateNumberOfMessagesVisible` | Gauge | Queue depth |
| `ElastiCache:CPUUtilization` | Gauge | Redis CPU usage |
| `ElastiCache:DatabaseMemoryUsagePercentage` | Gauge | Redis memory usage |

### X-Ray Tracing

Each request generates an X-Ray trace:

```json
{
  "id": "trace-id",
  "duration": 0.123,
  "http": {
    "request": {
      "method": "POST",
      "url": "/mcp",
      "user_agent": "agent-mesh/1.0"
    },
    "response": {
      "status": 200,
      "content_length": 1024
    }
  },
  "aws": {
    "ecs": {
      "cluster": "mcp-prod",
      "container_name": "mcp-server"
    }
  },
  "annotations": {
    "mcp.method": "tools/call",
    "mcp.tool": "handle_message",
    "session.id": "abc-123"
  }
}
```

### Alert Policies

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EKS cluster CPU is too high"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

---

## Deployment Patterns

### Blue/Green Deployment

```hcl
# Create new deployment
resource "kubernetes_deployment" "new" {
  metadata {
    name = "${var.deployment_name}-v2"
  }
  spec {
    # Same as current but with new image
  }
}

# Gradually shift traffic using service selector
resource "kubernetes_service" "this" {
  spec {
    selector = {
      app = var.deployment_name
      version = "v2"  # Update to new version
    }
  }
}
```

### Canary Deployment

```hcl
# Use Istio or AWS App Mesh for traffic splitting
# 90% to stable, 10% to canary
resource "kubernetes_manifest" "virtual_service" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    spec = {
      http = [
        {
          route = [
            { destination = { host = "mcp-server", subset = "stable" }, weight = 90 },
            { destination = { host = "mcp-server", subset = "canary" }, weight = 10 }
          ]
        }
      ]
    }
  }
}
```

---

## Failure Modes

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Pod crash loop | Kubernetes restart count | Check logs, increase resources |
| ElastiCache unavailable | Connection timeout | Retry with backoff, fail open for reads |
| SQS processing failure | Message returns to queue | Retry up to maxReceiveCount, then DLQ |
| Node failure | Kubernetes node not ready | Auto-scaling replaces node |
| High latency | X-Ray trace duration | Scale up warm pool, optimize code |
| IRSA permission denied | CloudWatch log error | Check IAM role trust policy |

---

## Cost Model

### Pricing Components

| Component | Pricing | Example Monthly Cost |
|-----------|---------|---------------------|
| EKS | $0.10/hour per cluster | $72 |
| EC2 (t3.medium) | $0.0416/hour each | $30 each |
| ElastiCache (cache.t3.micro) | $0.017/hour | $12 |
| SQS | $0.40/million requests | $4 (100k messages) |
| Secrets Manager | $0.40/secret/month | $2 (5 secrets) |
| CloudWatch | Free tier + usage | $10 |
| X-Ray | $5 per 100k traces | $5 |

**Total estimated monthly cost for medium traffic: ~$180**

### Cost Optimization Strategies

1. **Scale-to-zero** — Use KEDA to scale to 0 when idle
2. **Spot instances** — Use spot for non-critical workloads
3. **Right-size nodes** — Match node types to workload
4. **Warm pool tuning** — Minimize warm pods while maintaining SLA
5. **Budget alerts** — Set up billing alerts at 50%, 75%, 90%

---

## References

- **AGENTS.md** — Agent deployment guide
- **DEV_PLAN.md** — Development checklist
- **README.md** — Quick start and module reference
- **terraform-mcp-cloudrun/ARCHITECTURE.md** — GCP Cloud Run patterns
- **EKS Best Practices** — https://aws.github.io/aws-eks-best-practices/
- **KEDA Documentation** — https://keda.sh/docs/
