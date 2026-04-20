# MCP Service Module

Deploy an MCP workload to Kubernetes with IRSA, probes, HPA, and optional KEDA `ScaledObject` resources for SQS-driven scaling.

## Usage

```hcl
module "mcp_service" {
  source = "github.com/reaatech/terraform-mcp-aws-eks//modules/mcp-service"

  namespace            = "mcp"
  deployment_name      = "mcp-server"
  region               = var.region
  image                = var.mcp_server_image
  service_account_name = "mcp-server"
  iam_role_arn         = module.iam.role_arns["mcp-server"]
  sqs_queue_url        = module.sqs.queue_urls["mcp-tasks"]
}
```
