# Empaqueta el código Python
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.lambda_src
  output_path = "${path.module}/alert.zip"
}

# Grupo de logs para la Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.prefix}-alerts-${terraform.workspace}"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, {
    Name = "${var.prefix}-alerts-logs-${terraform.workspace}"
    Workspace = terraform.workspace
  })
}

# Función Lambda
resource "aws_lambda_function" "alerts" {
  function_name = "${var.prefix}-alerts-${terraform.workspace}"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  handler       = "alert.lambda_handler"
  runtime       = "python3.9"
  role          = data.aws_iam_role.lambda_exec.arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      ENVIRONMENT   = terraform.workspace
    }
  }

  # Asegurar que el grupo de logs exista antes de crear la Lambda
  depends_on = [aws_cloudwatch_log_group.lambda_logs]

  tags = merge(var.tags, {
    Name = "${var.prefix}-alerts-${terraform.workspace}"
    Workspace = terraform.workspace
    Function = "alerts"
  })
}

# IAM Role existente (LabRole) para ejecución de Lambdas
data "aws_iam_role" "lambda_exec" {
  name = "LabRole"
}

# Permitir a SNS invocar la Lambda
resource "aws_lambda_permission" "sns_pub" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alerts.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

# Alarma para errores de la Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.prefix}-alerts-errors-${terraform.workspace}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Monitorea errores en la función Lambda de alertas"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.alerts.function_name
  }
  
  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]
  
  tags = merge(var.tags, {
    Name = "${var.prefix}-alerts-alarm-${terraform.workspace}"
    Workspace = terraform.workspace
  })
}
