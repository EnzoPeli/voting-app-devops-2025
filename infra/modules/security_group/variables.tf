variable "vpc_id" {
  description = "ID de la VPC donde se creará el Security Group"
  type        = string
}

variable "sg_name" {
  description = "Nombre del Security Group"
  type        = string
  default     = "sg-voting-app"
}

variable "ingress_rules" {
  description = "Lista de reglas de ingreso (ingress)" 
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "egress_rules" {
  description = "Lista de reglas de salida (egress)"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "tags" {
  description = "Tags que aplicar al Security Group"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "voting-app"
  }
}
