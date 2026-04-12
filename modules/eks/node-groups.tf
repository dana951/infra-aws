resource "aws_eks_node_group" "private" {
  for_each = var.private_node_groups

  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.private_subnet_ids
  version         = var.cluster_version

  ami_type      = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"
  disk_size     = each.value.disk_size

  instance_types = each.value.instance_types

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = each.value.max_unavailable
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  labels = each.value.labels

  tags = merge(
    var.common_tags,
    each.value.tags,
    { Name = "${var.name_prefix}-${var.cluster_name}-${each.key}" },
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_node_group" "public" {
  for_each = var.public_node_groups

  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.public_subnet_ids
  version         = var.cluster_version

  ami_type      = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"
  disk_size     = each.value.disk_size

  instance_types = each.value.instance_types

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = each.value.max_unavailable
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  labels = each.value.labels

  tags = merge(
    var.common_tags,
    each.value.tags,
    { Name = "${var.name_prefix}-${var.cluster_name}-${each.key}" },
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}
