variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidrs" {
  description = "Lista de CIDR blocks para las subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "region" {
  description = "Región de AWS donde se creara la VPC"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Lista de Availability Zones donde crear subnets"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags que aplicar a todos los recursos de red"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "voting-app"
  }
}
