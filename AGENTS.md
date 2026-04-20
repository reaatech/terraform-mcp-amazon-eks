---
agent_id: "terraform-mcp-aws-eks"
display_name: "Terraform MCP AWS EKS"
version: "1.0.0"
description: "MCP server for deploying agents on AWS EKS using Terraform"
type: "mcp"
confidence_threshold: 0.9
---

# terraform-mcp-aws-eks — Agent Deployment Guide

## What this is

This document defines how to use `terraform-mcp-aws-eks` to deploy MCP servers on Amazon EKS
with the FaaS-runtime-style hot-pod pattern. It covers module usage, configuration patterns,
security considerations, and integration with multi-agent systems like `agent-mesh`.

**Target audience:** Platform engineers and DevOps teams deploying MCP servers to AWS
who need a battle-tested infrastructure template with observability, security, and
scalability built in.

---

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   MCP Client    │────▶│   EKS Cluster    │────▶│  ElastiCache    │
│  (agent-mesh)   │     │  (Hot-Pod Pattern)│    │  (Sessions)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ Secrets Manager  │
                       │  (API Keys)      │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │      SQS         │
                       │  (Async Tasks)   │
                       └──────────────────┘
```

### Key Components

| Component | Module | Purpose |
|-----------|--------|---------|
| **EKS Cluster** | `modules/eks/` | Kubernetes cluster with managed node groups |
| **KEDA Install** | `modules/keda/` | Helm installation of the KEDA operator |
| **Hot-Pod Pattern** | `modules/mcp-service/` | Pre-warmed pods with HPA and KEDA scaling |
| **ElastiCache** | `modules/elasticache/` | Redis for session state |
| **Secrets Manager** | `modules/secrets/` | API keys and credentials |
| **SQS** | `modules/sqs/` | Async task distribution |
| **IAM** | `modules/iam/` | IRSA roles and permissions |
| **Monitoring** | `modules/monitoring/` | CloudWatch and X-Ray |

---

## Quick Start

### Prerequisites

- Terraform >= 1.6
- `aws` CLI configured (`aws configure`)
- `kubectl` and `helm` installed
- An AWS account with appropriate permissions
- An S3 bucket for remote state

### 5-Minute Deployment

```bash
# 1. Clone the module
git clone https://github.com/reaatech/terraform-mcp-aws-eks.git
cd terraform-mcp-aws-eks/environments/dev

# 2. Configure backend
cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket = "your-tfstate-bucket"
    key    = "terraform/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
EOF

# 3. Configure variables
cat > terraform.tfvars <<EOF
region       = "us-west-2"
cluster_name = "mcp-dev"
subnet_ids   = ["subnet-111", "subnet-222", "subnet-333"]
EOF

# 4. Deploy
terraform init
terraform plan
terraform apply
```

### Verify Deployment

```bash
# Get kubeconfig
aws eks update-kubeconfig --name mcp-dev --region us-west-2

# Check pods
kubectl get pods -n mcp

# Check ElastiCache
aws elasticache describe-cache-clusters --cache-cluster-id mcp-dev-redis

# Check SQS queues
aws sqs list-queues --queue-name-prefix mcp-dev
```

---

## Module Usage

### Basic Single-Service Deployment

```hcl
module "mcp_eks" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/eks"

  cluster_name = "mcp-prod"
  subnet_ids   = var.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 10
    }
  }

  kubernetes_version = "1.30"

  tags = {
    Environment = "prod"
  }
}
```

### KEDA Installation

```hcl
module "keda" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/keda"

  namespace = "keda"
}
```

### Hot-Pod Deployment with KEDA

```hcl
module "keda" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/mcp-service"

  namespace       = "mcp"
  deployment_name = "mcp-server"
  region          = var.region
  image           = var.mcp_server_image
  iam_role_arn    = module.iam.role_arns["mcp-server"]
  service_account_name = "mcp-server"

  min_replicas     = 0   # Scale to zero
  max_replicas     = 20
  warm_pool_size   = 2   # Keep 2 pods warm

  scale_up_threshold = 5   # Scale up when 5 messages in queue
  scale_down_delay   = 300 # Wait 5 minutes before scaling down

  sqs_queue_url = module.sqs.queue_urls["mcp-tasks"]
}
```

### Multi-Service with SQS

```hcl
module "sqs" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/sqs"

  queues = {
    tasks   = { visibility_timeout = 30, delay_seconds = 0 }
    results = { visibility_timeout = 60, delay_seconds = 0 }
    events  = { visibility_timeout = 30, delay_seconds = 0 }
  }

  dead_letter_queue = "mcp-dlq"
}
```

---

## Configuration Reference

### EKS Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_name` | string | — | EKS cluster name |
| `subnet_ids` | list(string) | — | Private subnet IDs |
| `node_groups` | map(object) | — | Node group definitions |
| `enable_encryption` | bool | `true` | Enable KMS envelope encryption for secrets |

### Hot-Pod Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `min_replicas` | number | 0 | Minimum replicas |
| `max_replicas` | number | 10 | Maximum replicas |
| `warm_pool_size` | number | 1 | Pre-warmed pods |
| `scale_up_threshold` | number | 10 | Queue depth for scale-up |
| `scale_down_delay` | number | 300 | Seconds before scale-down |

### ElastiCache Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `node_type` | string | "cache.t3.micro" | Node type |
| `num_cache_nodes` | number | 1 | Number of nodes |
| `engine_version` | string | "7.0" | Redis version |

---

## Security Model

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────────────┐
│ Layer 1: Network                                                     │
│ - Private subnets only                                              │
│ - Security groups with minimal ingress                              │
│ - VPC endpoints for AWS services                                    │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 2: Identity                                                    │
│ - IRSA for pod-level IAM                                            │
│ - Least privilege policies                                          │
│ - No node-level IAM permissions                                     │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 3: Secrets                                                     │
│ - Secrets Manager for all credentials                               │
│ - KMS encryption                                                    │
│ - Automatic rotation support                                        │
├─────────────────────────────────────────────────────────────────────┤
│ Layer 4: Data                                                        │
│ - ElastiCache encryption at rest                                    │
│ - TLS in transit                                                    │
│ - PII redaction in logs                                             │
└─────────────────────────────────────────────────────────────────────┘
```

### IRSA Configuration

```hcl
# Create IAM role for service account
module "iam" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/iam"

  cluster_name = module.mcp_eks.cluster_name

  service_accounts = {
    mcp-server = {
      namespace = "mcp"
      policies  = ["secrets-access", "sqs-access", "elasticache-access"]
    }
  }
}
```

---

## Observability

### CloudWatch Dashboard

The monitoring module creates a dashboard with:

- **Pod metrics** — CPU, memory, restart count
- **Node metrics** — CPU, memory, disk utilization
- **SQS metrics** — Queue depth, age of oldest message
- **ElastiCache metrics** — CPU, memory, connections
- **X-Ray traces** — Request latency and errors

### Alert Policies

> **Note:** The included monitoring module provides a CloudWatch dashboard and X-Ray sampling rules. For CloudWatch Alarms, enable [Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html) and configure alarms based on the metrics it provides (e.g., pod CPU/memory, node utilization).
>
> Recommended alarms to configure separately:
>
> | Alert | Condition | Severity |
> |-------|-----------|----------|
> | High pod restart count | Restarts > 5 in 5m | Critical |
> | High SQS queue depth | Depth > 100 for 5m | Warning |
> | ElastiCache high CPU | CPU > 80% for 5m | Warning |
> | Node high memory | Memory > 90% for 5m | Critical |

---

## Cost Optimization

### Right-Sizing

| Workload | Node Type | Min/Max Nodes | Warm Pods |
|----------|-----------|---------------|-----------|
| Dev | t3.small | 1/3 | 0 |
| Medium | t3.medium | 2/5 | 1 |
| High traffic | t3.large | 3/10 | 2 |

### Cost Estimation

```
EKS: $0.10/hour per cluster (~$72/month)
EC2: t3.medium ~$0.0416/hour (~$30/month each)
ElastiCache: cache.t3.micro ~$0.017/hour (~$12/month)
SQS: $0.40 per million requests
Secrets Manager: $0.40/secret/month
```

**Example monthly cost for medium traffic:**
- EKS: ~$72
- EC2 (3 nodes): ~$90
- ElastiCache: ~$12
- SQS: ~$4 (100k messages)
- Secrets Manager: ~$2 (5 secrets)
- **Total: ~$180/month**

---

## Integration with Multi-Agent Systems

### Register with agent-mesh

```yaml
# agents/my-mcp-server.yaml
agent_id: my-mcp-server
display_name: My MCP Server (EKS)
description: >-
  MCP server deployed on EKS with hot-pod pattern,
  ElastiCache sessions, and SQS async task distribution.
endpoint: "${MY_MCP_SERVER_URL}"
type: mcp
is_default: false
confidence_threshold: 0.8
examples:
  - "Query my MCP server for data"
  - "Process async tasks via SQS"
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Pods not starting | IRSA misconfiguration | Check IAM role trust policy |
| High latency | Insufficient warm pods | Increase `warm_pool_size` |
| ElastiCache timeout | Security group blocking | Allow port 6379 from EKS |
| SQS not processing | Missing IAM permissions | Add `sqs:ReceiveMessage` to IRSA |

### Debug Commands

```bash
# Check pod status
kubectl get pods -n mcp -o wide

# View pod logs
kubectl logs -n mcp deployment/mcp-server

# Check ElastiCache connectivity
kubectl run redis-test --image=redis:alpine --rm -it -- redis-cli -h <redis-endpoint> ping

# Check SQS queue depth
aws sqs get-queue-attributes --queue-url <queue-url> --attribute-names ApproximateNumberOfMessages
```

---

## Checklist: Production Readiness

Before deploying to production:

- [ ] IRSA roles configured with least privilege
- [ ] Private subnets for all EKS resources
- [ ] ElastiCache encryption enabled
- [ ] Container Insights enabled and CloudWatch alarms configured
- [ ] X-Ray tracing enabled
- [ ] SQS DLQ configured
- [ ] Secrets created in Secrets Manager
- [ ] Remote state configured with locking
- [ ] CI/CD pipeline validates Terraform changes
- [ ] Disaster recovery plan documented

---

## References

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System design deep dive
- **[DEV_PLAN.md](DEV_PLAN.md)** — Development checklist
- **[SECURITY.md](SECURITY.md)** — Security policy
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — Contribution guidelines
- **skills/** — Specialized skills for hot-pod, security, observability, and cost optimization
- **EKS Best Practices** — https://aws.github.io/aws-eks-best-practices/
