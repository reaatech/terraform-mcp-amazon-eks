variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "mcp-prod"
}

variable "subnet_ids" {
  description = "Private subnet IDs for the deployment"
  type        = list(string)
}

variable "mcp_server_image" {
  description = "Container image for the MCP server"
  type        = string
}

variable "alert_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = null
}

variable "redis_auth_token" {
  description = "Redis auth token for ElastiCache"
  type        = string
  sensitive   = true
}
