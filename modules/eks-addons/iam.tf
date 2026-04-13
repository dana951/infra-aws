locals {
  efs_csi_iam_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

resource "aws_iam_role" "efs_csi_iam_role" {
  count = var.enable_efs_csi_driver ? 1 : 0

  name = "${var.name_prefix}-${var.cluster_name}-efs-csi-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_issuer_hostpath}:aud" = "sts.amazonaws.com"
            "${var.oidc_issuer_hostpath}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-${var.cluster_name}-efs-csi-iam-role"
    },
  )
}

resource "aws_iam_role_policy_attachment" "efs_csi_iam_role_policy_attach" {
  count = var.enable_efs_csi_driver ? 1 : 0

  role       = aws_iam_role.efs_csi_iam_role[0].name
  policy_arn = local.efs_csi_iam_policy_arn
}
