output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Lista de IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "public_route_table_id" {
  description = "ID de la route table pública"
  value       = aws_route_table.public_rt.id
}


