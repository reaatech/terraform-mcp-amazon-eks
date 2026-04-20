variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment label applied to resources"
  type        = string
  default     = "default"
}

variable "vpc_id" {
  description = "Optional VPC ID to discover subnets from when subnet_ids is not provided"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Optional subnet IDs to use for EKS and ElastiCache. Defaults to all subnets in the selected or default VPC."
  type        = list(string)
  default     = null
}

variable "cluster_security_group_ids" {
  description = "Additional security groups for the EKS control plane"
  type        = list(string)
  default     = []
}

variable "mcp_server_image" {
  description = "Container image for the MCP service"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the MCP workload"
  type        = string
  default     = "mcp"
}

variable "deployment_name" {
  description = "Kubernetes deployment and service name for the MCP workload"
  type        = string
  default     = "mcp-server"
}

variable "service_account_name" {
  description = "Service account name used by the MCP workload"
  type        = string
  default     = "mcp-server"
}

variable "node_groups" {
  description = "Managed node group definitions for the EKS cluster"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = optional(number)
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
  }))
  default = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
    }
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "enable_cluster_encryption" {
  description = "Enable KMS envelope encryption for Kubernetes secrets"
  type        = bool
  default     = true
}

variable "cluster_kms_key_id" {
  description = "Existing KMS key ARN for EKS secrets encryption"
  type        = string
  default     = null
}

variable "endpoint_private_access" {
  description = "Enable private access to the Kubernetes API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the Kubernetes API endpoint"
  type        = bool
  default     = true
}

variable "enable_keda" {
  description = "Install the KEDA operator via Helm"
  type        = bool
  default     = true
}

variable "keda_release_name" {
  description = "Helm release name for the KEDA installation"
  type        = string
  default     = "keda"
}

variable "keda_namespace" {
  description = "Namespace for the KEDA operator"
  type        = string
  default     = "keda"
}

variable "keda_chart_version" {
  description = "Optional pinned KEDA chart version"
  type        = string
  default     = null
}

variable "keda_values" {
  description = "Raw Helm values for the KEDA chart"
  type        = list(string)
  default     = []
}

variable "enable_keda_scaling" {
  description = "Create KEDA TriggerAuthentication and ScaledObject resources"
  type        = bool
  default     = true
}

variable "enable_hpa" {
  description = "Create an HPA for CPU and memory scaling"
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Minimum replicas for the MCP deployment"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum replicas for the MCP deployment"
  type        = number
  default     = 10
}

variable "warm_pool_size" {
  description = "Starting replica count for the MCP deployment"
  type        = number
  default     = 1
}

variable "scale_up_threshold" {
  description = "SQS queue depth target for KEDA scaling"
  type        = number
  default     = 5
}

variable "activation_queue_length" {
  description = "KEDA activation queue depth"
  type        = number
  default     = 0
}

variable "scale_down_delay" {
  description = "Cooldown period for KEDA scale-down in seconds"
  type        = number
  default     = 300
}

variable "scale_on_in_flight" {
  description = "Include in-flight SQS messages when scaling"
  type        = bool
  default     = true
}

variable "scale_on_delayed" {
  description = "Include delayed SQS messages when scaling"
  type        = bool
  default     = false
}

variable "cpu_request" {
  description = "CPU request for the MCP workload"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for the MCP workload"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit for the MCP workload"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for the MCP workload"
  type        = string
  default     = "1024Mi"
}

variable "target_cpu_utilization" {
  description = "CPU utilization target for HPA"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Memory utilization target for HPA"
  type        = number
  default     = 80
}

variable "env_vars" {
  description = "Additional environment variables passed to the MCP workload"
  type        = map(string)
  default     = {}
}

variable "kubernetes_secret_env_vars" {
  description = "Optional Kubernetes Secret-backed environment variables"
  type = map(object({
    secret_name = string
    secret_key  = string
  }))
  default = {}
}

variable "node_selector" {
  description = "Node selector for MCP workload scheduling"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for MCP workload scheduling"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

variable "service_type" {
  description = "Kubernetes Service type for the MCP workload"
  type        = string
  default     = "ClusterIP"
}

variable "sqs_queues" {
  description = "Optional map of SQS queues to create. Defaults to cluster-scoped task and result queues."
  type = map(object({
    visibility_timeout_seconds  = optional(number, 30)
    message_retention_seconds   = optional(number, 345600)
    delay_seconds               = optional(number, 0)
    receive_wait_time_seconds   = optional(number, 20)
    content_based_deduplication = optional(bool, false)
    fifo_queue                  = optional(bool, false)
  }))
  default = {}
}

variable "task_queue_name" {
  description = "Name of the SQS queue used to drive KEDA scaling"
  type        = string
  default     = null
}

variable "dead_letter_queue_name" {
  description = "Optional dead-letter queue name"
  type        = string
  default     = null
}

variable "sqs_kms_master_key_id" {
  description = "Optional KMS key for SQS encryption"
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "How many times a message is retried before moving to the DLQ"
  type        = number
  default     = 5
}

variable "queue_policies" {
  description = "Optional queue policies keyed by queue name"
  type        = map(string)
  default     = {}
}

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_nodes" {
  description = "Number of cache nodes in the ElastiCache replication group"
  type        = number
  default     = 1
}

variable "elasticache_engine_version" {
  description = "ElastiCache engine version"
  type        = string
  default     = "7.0"
}

variable "elasticache_parameter_group_name" {
  description = "Optional ElastiCache parameter group name"
  type        = string
  default     = ""
}

variable "elasticache_snapshot_retention_days" {
  description = "Snapshot retention period for ElastiCache"
  type        = number
  default     = 7
}

variable "elasticache_maintenance_window" {
  description = "Optional ElastiCache maintenance window"
  type        = string
  default     = ""
}

variable "elasticache_notification_topic_arn" {
  description = "Optional SNS topic for ElastiCache notifications"
  type        = string
  default     = null
}

variable "elasticache_at_rest_encryption_enabled" {
  description = "Enable ElastiCache encryption at rest"
  type        = bool
  default     = true
}

variable "elasticache_transit_encryption_enabled" {
  description = "Enable ElastiCache TLS in transit"
  type        = bool
  default     = true
}

variable "elasticache_multi_az_enabled" {
  description = "Enable ElastiCache Multi-AZ mode"
  type        = bool
  default     = false
}

variable "elasticache_auth_token" {
  description = "Optional Redis auth token for ElastiCache"
  type        = string
  default     = null
  sensitive   = true
}

variable "create_api_key_secret" {
  description = "Create a default Secrets Manager secret for the MCP API key"
  type        = bool
  default     = true
}

variable "api_key_value" {
  description = "Optional initial API key value stored in the default secret"
  type        = string
  default     = null
  sensitive   = true
}

variable "secrets" {
  description = "Additional Secrets Manager secret definitions"
  type = map(object({
    secret_id   = string
    description = optional(string, "")
    kms_key_id  = optional(string)
  }))
  default = {}
}

variable "secret_values" {
  description = "Optional initial secret values for the secret map"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "secret_recovery_window_in_days" {
  description = "Recovery window for deleting Secrets Manager secrets"
  type        = number
  default     = 7
}

variable "managed_policy_arns" {
  description = "Additional AWS managed policies to attach to the MCP workload role"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Optional email for CloudWatch alarm notifications"
  type        = string
  default     = null
}

variable "xray_enabled" {
  description = "Create an X-Ray sampling rule"
  type        = bool
  default     = true
}

variable "enable_alarms" {
  description = "Create SQS and ElastiCache CloudWatch alarms"
  type        = bool
  default     = true
}

variable "sqs_depth_alarm_threshold" {
  description = "SQS queue depth alarm threshold"
  type        = number
  default     = 100
}

variable "elasticache_cpu_alarm_threshold" {
  description = "ElastiCache CPU alarm threshold"
  type        = number
  default     = 80
}

variable "elasticache_memory_alarm_threshold" {
  description = "ElastiCache memory alarm threshold"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Additional tags applied to AWS resources"
  type        = map(string)
  default     = {}
}
