output "enabled_addons" {
  description = "Enabled addon details keyed by addon name."
  value = {
    for addon_name, addon in aws_eks_addon.addons : addon_name => {
      arn     = addon.arn
      version = addon.addon_version
    }
  }
}

output "addon_irsa_roles" {
  description = "IRSA role details keyed by addon name."
  value = {
    for addon_name, role in aws_iam_role.addon_iam_role : addon_name => {
      name = role.name
      arn  = role.arn
      id   = role.id
    }
  }
}
