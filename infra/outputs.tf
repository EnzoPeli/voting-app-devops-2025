output "vpc_id" {
  description = "ID de la VPC creada por el módulo network"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas creadas"
  value       = module.network.public_subnet_ids
}

output "public_route_table_id" {
  description = "ID de la route table pública"
  value       = module.network.public_route_table_id
}

output "security_group_id" {
  description = "ID del Security Group creado"
  value       = module.security_group.sg_id
}

output "security_group_arn" {
  description = "ARN del Security Group creado"
  value       = module.security_group.sg_arn
}

output "ecr_vote_url" {
  value       = module.ecr_vote.repository_url
  description = "URL completo del repositorio ECR"
}

output "ecr_result_url" {
  value       = module.ecr_result.repository_url
  description = "URL completo del repositorio ECR"
}

output "ecr_seed_url" {
  value       = module.ecr_seed.repository_url
  description = "URL completo del repositorio ECR"
}

output "ecr_worker_url" {
  value       = module.ecr_worker.repository_url
  description = "URL completo del repositorio ECR"
}
