resource "aws_security_group" "efs_sg" {
  name        = "${var.name}-sg"
  description = "EFS mount target SG"
  vpc_id      = var.vpc_id

  # Allow inbound NFS from the provided SGs (EKS nodes / cluster SG)
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "NFS from worker nodes"
  }

  # Egress – allow everything
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

resource "aws_efs_file_system" "this" {
  creation_token   = var.name
  encrypted        = true
  throughput_mode  = "bursting"

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_efs_mount_target" "this" {
  count            = length(var.subnet_ids)
  file_system_id   = aws_efs_file_system.this.id
  subnet_id        = var.subnet_ids[count.index]
  security_groups  = [aws_security_group.efs_sg.id]
}

resource "aws_efs_access_point" "this" {
  count          = var.create_access_point ? 1 : 0
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = var.posix_uid
    gid = var.posix_gid
  }

  root_directory {
    path = "/"
    creation_info {
      owner_uid   = var.posix_uid
      owner_gid   = var.posix_gid
      permissions = "0755"
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-ap" })
}
