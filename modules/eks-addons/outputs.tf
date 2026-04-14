output "enabled_addons" {
  description = "Enabled addon details keyed by addon name."
  value = {
    for addon_name, addon in aws_eks_addon.addons : addon_name => {
      arn     = addon.arn
      version = addon.addon_version
      status  = addon.status
    }
  }
}

output "addon_irsa_roles" {
  description = "IRSA role details keyed by addon name for addons that define irsa."
  value = {
    for addon_name, role in aws_iam_role.addon_iam_role : addon_name => {
      name = role.name
      arn  = role.arn
      id   = role.id
    }
  }
}

output "enabled_helm_charts" {
  description = "Enabled Helm releases keyed by release name."
  value = {
    for release_name, release in helm_release.release : release_name => {
      name      = release.name
      namespace = release.namespace
      status    = release.status
      version   = release.version
    }
  }
}

output "helm_chart_irsa_roles" {
  description = "IRSA role details keyed by Helm release name when irsa is configured."
  value = {
    for release_name, role in aws_iam_role.helm_chart_iam_role : release_name => {
      name = role.name
      arn  = role.arn
      id   = role.id
    }
  }
}
