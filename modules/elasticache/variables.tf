variable "cluster_id" {
  description = "ElastiCache cluster identifier"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type (e.g., cache.t3.micro)"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of nodes in the ElastiCache cluster"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ElastiCache subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the ElastiCache cluster"
  type        = list(string)
}

variable "port" {
  description = "Port for the ElastiCache cluster"
  type        = number
  default     = 6379
}

variable "parameter_group_name" {
  description = "Name of the ElastiCache parameter group"
  type        = string
  default     = ""
}

variable "snapshot_retention_days" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Weekly time range for maintenance (e.g., sun:05:00-sun:09:00)"
  type        = string
  default     = ""
}

variable "notification_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
  default     = null
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ for high availability"
  type        = bool
  default     = false
}

variable "transit_encryption_enabled" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Authentication token for the Redis cluster"
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
