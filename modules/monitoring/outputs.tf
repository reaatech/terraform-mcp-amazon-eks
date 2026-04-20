output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = try(aws_sns_topic.alerts[0].arn, null)
}

output "alarm_names" {
  description = "Names of the CloudWatch alarms"
  value = concat(
    [for alarm in aws_cloudwatch_metric_alarm.sqs_depth : alarm.alarm_name],
    compact([
      try(aws_cloudwatch_metric_alarm.elasticache_cpu[0].alarm_name, ""),
      try(aws_cloudwatch_metric_alarm.elasticache_memory[0].alarm_name, "")
    ])
  )
}
