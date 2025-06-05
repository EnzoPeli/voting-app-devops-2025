variable "aws_region" {
  description = "Región AWS"
  type        = string
}

variable "aws_profile" {
  description = "Perfil AWS CLI"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC del módulo network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidrs" {
  description = "Lista de CIDR blocks para las subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability Zones donde crear las subnets"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Mapa de etiquetas comunes a aplicar a los recursos"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "voting-app"
  }
}