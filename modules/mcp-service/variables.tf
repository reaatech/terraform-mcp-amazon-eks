variable "namespace" {
  description = "Kubernetes namespace for the MCP server deployment"
  type        = string
}

variable "deployment_name" {
  description = "Name of the Kubernetes deployment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "image" {
  description = "Container image for the MCP server"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name for IRSA"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role ARN for IRSA"
  type        = string
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 20
}

variable "warm_pool_size" {
  description = "Number of pre-warmed pods to keep alive"
  type        = number
  default     = 1
}

variable "scale_up_threshold" {
  description = "SQS queue depth to trigger scale-up"
  type        = number
  default     = 5
}

variable "activation_queue_length" {
  description = "Queue depth required before KEDA activates scaling"
  type        = number
  default     = 0
}

variable "scale_down_delay" {
  description = "Seconds to wait before scaling down"
  type        = number
  default     = 300
}

variable "sqs_queue_url" {
  description = "SQS queue URL for KEDA scaling triggers"
  type        = string
}

variable "scale_on_in_flight" {
  description = "Include in-flight SQS messages when computing scale"
  type        = bool
  default     = true
}

variable "scale_on_delayed" {
  description = "Include delayed SQS messages when computing scale"
  type        = bool
  default     = false
}

variable "cpu_request" {
  description = "CPU request for the MCP server container"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for the MCP server container"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit for the MCP server container"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for the MCP server container"
  type        = string
  default     = "1024Mi"
}

variable "env_vars" {
  description = "Environment variables for the MCP server"
  type        = map(string)
  default     = {}
}

variable "kubernetes_secret_env_vars" {
  description = "Kubernetes Secret-backed environment variables"
  type = map(object({
    secret_name = string
    secret_key  = string
  }))
  default = {}
}

variable "create_namespace" {
  description = "Create the Kubernetes namespace if it does not exist"
  type        = bool
  default     = true
}

variable "enable_hpa" {
  description = "Enable HPA for CPU and memory scaling"
  type        = bool
  default     = true
}

variable "enable_keda_scaling" {
  description = "Enable KEDA ScaledObject resources for SQS-based scaling"
  type        = bool
  default     = true
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80
}

variable "node_selector" {
  description = "Node selector for pod scheduling"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for pod scheduling"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
}

variable "tags" {
  description = "Tags applied as labels to workload resources"
  type        = map(string)
  default     = {}
}
