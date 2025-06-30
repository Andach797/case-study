output "role_arn" {
  description = "ARN for adding as AWS_ROLE_ARN github secrets"
  value       = aws_iam_role.this.arn
}

output "oidc_provider_arn" {
  description = "ARN of the gha OIDC provider that this module creates."
  value       = aws_iam_openid_connect_provider.github.arn
}
