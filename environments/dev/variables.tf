variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "mcp-dev"
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS and ElastiCache deployment"
  type        = list(string)
  default     = null
}

variable "mcp_server_image" {
  description = "Container image for the MCP server"
  type        = string
  default     = "public.ecr.aws/example/mcp-server:latest"
}

variable "alert_email" {
  description = "Optional email address for alarms"
  type        = string
  default     = null
}
