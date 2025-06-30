# Alarma de CloudWatch para monitorear CPU del cluster EKS
resource "aws_cloudwatch_metric_alarm" "eks_cpu_utilization" {
  alarm_name          = "eks-cpu-utilization-${terraform.workspace}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = "300"  # 5 minutos
  statistic           = "Average"
  threshold           = "80"   # 80% de CPU
  alarm_description   = "Alarma cuando la utilización de CPU del cluster EKS supera el 80%"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    ClusterName = module.eks_cluster.cluster_name
  }
  
  # Enviar notificación al tema SNS existente
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  
  tags = merge(var.tags, {
    Name = "eks-cpu-alarm-${terraform.workspace}"
    Environment = terraform.workspace
    Component = "monitoring"
  })
}

# Dashboard de CloudWatch para visualizar métricas del cluster EKS
resource "aws_cloudwatch_dashboard" "eks_dashboard" {
  dashboard_name = "eks-monitoring-${terraform.workspace}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", module.eks_cluster.cluster_name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EKS CPU Utilization (Promedio)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", module.eks_cluster.cluster_name, { "stat": "p50" }],
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", module.eks_cluster.cluster_name, { "stat": "p95" }]
          ]
          period = 300
          region = var.aws_region
          title  = "EKS CPU Utilization (p50/p95)"
        }
      }
    ]
  })
}
