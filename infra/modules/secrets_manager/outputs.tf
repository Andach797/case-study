output "arn" {
  description = "ARN of the created Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "name" {
  description = "Name of the created Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.name
}
