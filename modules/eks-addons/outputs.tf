output "efs_csi_driver_enabled" {
  description = "Whether the EFS CSI addon is enabled in this module."
  value       = var.enable_efs_csi_driver
}

output "efs_csi_iam_role_name" {
  description = "IAM role name used by aws-efs-csi-driver via IRSA."
  value       = var.enable_efs_csi_driver ? aws_iam_role.efs_csi_iam_role[0].name : null
}

output "efs_csi_iam_role_arn" {
  description = "IAM role ARN used by aws-efs-csi-driver via IRSA."
  value       = var.enable_efs_csi_driver ? aws_iam_role.efs_csi_iam_role[0].arn : null
}

output "efs_csi_iam_policy_arn" {
  description = "Managed policy ARN attached to the EFS CSI IRSA role."
  value       = local.efs_csi_iam_policy_arn
}

output "efs_csi_addon_arn" {
  description = "ARN of the aws-efs-csi-driver EKS addon."
  value       = var.enable_efs_csi_driver ? aws_eks_addon.efs_csi_driver[0].arn : null
}

output "efs_csi_addon_version" {
  description = "Installed version of aws-efs-csi-driver addon."
  value       = var.enable_efs_csi_driver ? aws_eks_addon.efs_csi_driver[0].addon_version : null
}

output "efs_csi_addon_status" {
  description = "Current status of aws-efs-csi-driver addon."
  value       = var.enable_efs_csi_driver ? aws_eks_addon.efs_csi_driver[0].status : null
}
