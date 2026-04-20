# Multi-Service Example

This example uses the root module with additional SQS queues to support orchestrator-style traffic patterns. It provisions one MCP workload plus task, result, and event queues so you can layer additional service-specific workloads on top of the same cluster using the submodules.
