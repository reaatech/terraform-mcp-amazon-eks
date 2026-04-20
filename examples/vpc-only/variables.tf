variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "mcp-vpc-only"
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "mcp_server_image" {
  description = "Container image for the MCP server"
  type        = string
  default     = "public.ecr.aws/example/mcp-server:latest"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = null
}
