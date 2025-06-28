variable "prefix" {
  description = "Prefijo para nombres de recursos"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del topic SNS para alertas"
  type        = string
}

variable "lambda_src" {
  description = "Ruta al fichero Python de la Lambda"
  type        = string
}

variable "timeout" {
  description = "Tiempo máximo de ejecución de la Lambda en segundos"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Memoria asignada a la Lambda en MB"
  type        = number
  default     = 128
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}
