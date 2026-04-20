# Data source for current region
data "aws_region" "current" {}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  count = var.alert_email != null ? 1 : 0

  name = "${var.cluster_name}-alerts"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != null ? 1 : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  alert_actions = var.alert_email != null ? [aws_sns_topic.alerts[0].arn] : []
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.cluster_name}-mcp-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# MCP Server Dashboard - ${var.cluster_name}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "cpu_utilization", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EKS Cluster CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "memory_utilization", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EKS Cluster Memory Utilization"
        }
      },
      {
        type   = "text"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          markdown = "## Container Insights\n\nEnable Container Insights for detailed pod and node CPU/memory metrics.\n\n[AWS Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            for queue in var.sqs_queue_names : ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", queue]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "SQS Queue Depth"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "ReplicationGroupId", var.elasticache_cluster_id]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ElastiCache Memory Usage"
        }
      }
    ]
  })
}

# X-Ray Sampling Rule
resource "aws_xray_sampling_rule" "mcp" {
  count = var.xray_enabled ? 1 : 0

  rule_name      = "${var.cluster_name}-mcp-sampling"
  priority       = 1000
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
  attributes     = {}

  version = 1
}

resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  for_each = var.enable_alarms ? toset(var.sqs_queue_names) : toset([])

  alarm_name          = "${var.cluster_name}-${each.value}-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = var.sqs_depth_alarm_threshold
  alarm_description   = "Queue depth alarm for ${each.value}"
  alarm_actions       = local.alert_actions
  ok_actions          = local.alert_actions

  dimensions = {
    QueueName = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.cluster_name}-redis-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.elasticache_cpu_alarm_threshold
  alarm_description   = "ElastiCache CPU alarm for ${var.elasticache_cluster_id}"
  alarm_actions       = local.alert_actions
  ok_actions          = local.alert_actions

  dimensions = {
    ReplicationGroupId = var.elasticache_cluster_id
    Role               = "Primary"
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_memory" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.cluster_name}-redis-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.elasticache_memory_alarm_threshold
  alarm_description   = "ElastiCache memory alarm for ${var.elasticache_cluster_id}"
  alarm_actions       = local.alert_actions
  ok_actions          = local.alert_actions

  dimensions = {
    ReplicationGroupId = var.elasticache_cluster_id
  }
}
