locals {
  enabled_addons = {
    for addon_name, addon in var.addons : addon_name => addon
    if addon.enabled
  }
}

data "aws_eks_addon_version" "latest_version" {
  for_each = var.addons

  addon_name         = each.key
  kubernetes_version = var.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "addons" {
  for_each = local.enabled_addons

  cluster_name           = var.cluster_name
  addon_name             = each.key
  addon_version          = try(each.value.addon_version, data.aws_eks_addon_version.latest_version[each.key].version)
  configuration_values   = each.value.configuration_values
  preserve               = each.value.preserve
  service_account_role_arn = aws_iam_role.addon_iam_role[each.key].arn

  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update

  timeouts {
    create = try(each.value.timeouts.create, var.eks_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.eks_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.eks_addons_timeouts.delete, null)
  }

  tags = merge(
    var.common_tags,
    try(each.value.tags, {}),
    {
      Name = "${var.name_prefix}-${var.cluster_name}-${each.key}"
    },
  )

  depends_on = [
    aws_iam_role_policy_attachment.addon_irsa_policy_attach,
  ]
}
