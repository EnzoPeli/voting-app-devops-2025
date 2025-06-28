output "repository_url" {
  description = "URL completa para hacer docker push/pull"
  value       = aws_ecr_repository.this.repository_url
}
