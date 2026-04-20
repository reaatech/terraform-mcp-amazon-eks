# SQS Module

SQS queues with dead-letter queue support, server-side encryption, and optional queue policies.

## Usage

```hcl
module "sqs" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/sqs"

  queues = {
    mcp-tasks = {
      visibility_timeout_seconds = 60
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 20
    }
    mcp-results = {
      visibility_timeout_seconds = 120
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 20
    }
  }

  dead_letter_queue = "mcp-dlq"
  max_receive_count = 3
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| aws | >= 5.0, < 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| queues | Queue definitions | `map(object)` | n/a | yes |
| dead_letter_queue | DLQ name | `string` | `null` | no |
| max_receive_count | Max receives before DLQ | `number` | `5` | no |
| kms_master_key_id | KMS key for SSE (null to auto-create) | `string` | `null` | no |
| queue_policies | Queue policies | `map(string)` | `{}` | no |
| tags | Tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| queue_urls | Map of queue names to URLs |
| queue_arns | Map of queue names to ARNs |
| dlq_url | Dead letter queue URL |
| dlq_arn | Dead letter queue ARN |

## Security

- Server-side encryption with KMS (auto-created key by default)
- Dead-letter queue for failed message handling
- Optional queue policies for cross-account access
