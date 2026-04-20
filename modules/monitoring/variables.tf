variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = null
}

variable "xray_enabled" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "sqs_queue_names" {
  description = "List of SQS queue names to monitor in the dashboard"
  type        = list(string)
  default     = ["mcp-tasks", "mcp-results"]
}

variable "elasticache_cluster_id" {
  description = "ElastiCache cluster identifier used in dashboard widgets and alarms"
  type        = string
}

variable "enable_alarms" {
  description = "Create CloudWatch alarms for SQS queue depth and ElastiCache utilization"
  type        = bool
  default     = true
}

variable "sqs_depth_alarm_threshold" {
  description = "Threshold for SQS visible message alarms"
  type        = number
  default     = 100
}

variable "elasticache_cpu_alarm_threshold" {
  description = "Threshold for ElastiCache CPU alarms"
  type        = number
  default     = 80
}

variable "elasticache_memory_alarm_threshold" {
  description = "Threshold for ElastiCache memory alarms"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
