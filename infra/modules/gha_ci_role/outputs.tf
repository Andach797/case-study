output "role_arn" {
  description = "ARN for adding as AWS_ROLE_ARN github secrets"
  value       = aws_iam_role.this.arn
}
