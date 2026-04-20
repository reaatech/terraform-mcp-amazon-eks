variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "mcp-multi-service"
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
  default     = null
}

variable "orchestrator_image" {
  description = "Container image for the MCP orchestrator server"
  type        = string
  default     = "public.ecr.aws/example/mcp-orchestrator:latest"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = null
}
