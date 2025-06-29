output "repository_url" {
  description = "URI (account.dkr.ecr.region.amazonaws.com/repo)"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.this.arn
}
