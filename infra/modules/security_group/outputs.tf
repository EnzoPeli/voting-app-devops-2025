output "sg_id" {
  description = "ID del Security Group creado"
  value       = aws_security_group.this.id
}

output "sg_arn" {
  description = "ARN del Security Group creado"
  value       = aws_security_group.this.arn
}

