resource "aws_eks_addon" "efs_csi_driver" {
  count = var.enable_efs_csi_driver ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "aws-efs-csi-driver"
  addon_version               = var.efs_csi_addon_version
  service_account_role_arn    = aws_iam_role.efs_csi_iam_role[0].arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-${var.cluster_name}-aws-efs-csi-driver"
    },
  )

  depends_on = [
    aws_iam_role_policy_attachment.efs_csi_iam_role_policy_attach,
  ]
}
