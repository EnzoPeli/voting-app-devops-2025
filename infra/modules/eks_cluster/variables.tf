variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
}

variable "node_group_name" {
  description = "Nombre del node group"
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM Role ARN para el control plane de EKS"
  type        = string
}

variable "node_role_arn" {
  description = "IAM Role ARN para los nodos EKS"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de subnets donde se desplegará EKS"
  type        = list(string)
}

variable "ec2_ssh_key_name" {
  description = "Nombre del par de claves para acceso SSH a los nodos"
  type        = string
}

variable "instance_types" {
  description = "Tipos de instancia para los nodos"
  type        = list(string)
  default     = ["t3.small"]
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 3
}

variable "tags" {
  description = "Etiquetas para aplicar"
  type        = map(string)
  default     = {}
}
