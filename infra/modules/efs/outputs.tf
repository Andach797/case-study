output "file_system_id" {
  value       = aws_efs_file_system.this.id
  description = "ID of the EFS file system"
}

output "security_group_id" {
  value       = aws_security_group.efs_sg.id
  description = "Security group that allows NFS traffic"
}

output "access_point_id" {
  value       = try(aws_efs_access_point.this[0].id, null)
  description = "Access-point ID (null if create_access_point=false)"
}
