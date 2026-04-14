locals {
  enabled_addons = {
    for addon_name, addon in var.addons : addon_name => addon
    if addon.enabled
  }
}

data "aws_eks_addon_version" "addon_version" {
  for_each = var.addons

  addon_name         = each.key
  kubernetes_version = var.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "addons" {
  for_each = local.enabled_addons

  cluster_name         = var.cluster_name
  addon_name           = each.key
  addon_version        = try(each.value.addon_version, data.aws_eks_addon_version.addon_version[each.key].version)
  configuration_values = try(each.value.configuration_values, null)
  preserve             = try(each.value.preserve, false)

  service_account_role_arn = aws_iam_role.addon_iam_role[each.key].arn

  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")

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
