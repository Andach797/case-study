############################################
# Iam Roles for EKS Cluster and Nodes
############################################

# Iam role for EKS control plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "eks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  })
  tags = merge(
    { Name = "${var.cluster_name}-eks-cluster-role", Project = var.project_tag, Environment = var.environment },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# Iam role for EKS worker nodes
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  })
  tags = merge(
    { Name = "${var.cluster_name}-eks-node-role", Project = var.project_tag, Environment = var.environment },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

############################################
# EKS Cluster Resource
############################################

resource "aws_eks_cluster" "cluster" {
  name    = var.cluster_name
  version = var.k8s_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids                 = var.subnet_ids
    endpoint_private_access    = var.cluster_endpoint_private_access
    endpoint_public_access     = var.cluster_endpoint_public_access
  }

  # all control plane log types
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(
    { Name = var.cluster_name, Project = var.project_tag, Environment = var.environment },
    var.tags
  )
}

# OIDC provider 
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  depends_on = [aws_eks_cluster.cluster]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge({
    Name        = "${var.cluster_name}-oidc"
    Project     = var.project_tag
    Environment = var.environment
  }, var.tags)
}

############################################
# EKS Managed Node Groups
############################################

resource "aws_eks_node_group" "managed" {
  for_each = var.managed_node_groups

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = lookup(each.value, "disk_size", 10)
  ami_type       = lookup(each.value, "ami_type", "AL2_x86_64")

  labels = lookup(each.value, "labels", {})

  tags = merge(
    {
      Name                                          = "${var.cluster_name}-${each.key}",
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "k8s.io/cluster-autoscaler/enabled"            = "true"
    },
    { Project = var.project_tag, Environment = var.environment },
    var.tags
  )
}
