output "role_arn" {
  description = "ARN of the gha Terraform role"
  value       = aws_iam_role.this.arn
}
