output "function_name" {
  description = "Nombre de la Lambda de Alerts"
  value       = aws_lambda_function.alerts.function_name
}

output "function_arn" {
  description = "ARN de la Lambda de Alerts"
  value       = aws_lambda_function.alerts.arn
}

output "log_group_name" {
  description = "Nombre del grupo de logs de CloudWatch"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "alarm_name" {
  description = "Nombre de la alarma de CloudWatch"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
}
