resource "helm_release" "release" {
  for_each = local.enabled_helm_charts

  name             = each.key
  namespace        = try(each.value.namespace, "default")
  repository       = each.value.repository
  chart            = each.value.chart
  version          = try(each.value.chart_version, null)
  create_namespace = try(each.value.create_namespace, false)
  values           = try(each.value.values, [])
  set = concat(
    try(each.value.set, []),
    try(each.value.irsa, null) != null ? [
      {
        name  = each.value.irsa.role_arn_set_name
        value = aws_iam_role.helm_chart_iam_role[each.key].arn
        type  = "string"
      },
    ] : [],
  )
  set_sensitive       = try(each.value.set_sensitive, [])
  wait                = try(each.value.wait, true)
  timeout             = try(each.value.timeout, 600)
  atomic              = try(each.value.atomic, true)
  cleanup_on_fail     = try(each.value.cleanup_on_fail, false)
  dependency_update   = try(each.value.dependency_update, false)

  depends_on = [
    aws_iam_role_policy_attachment.helm_chart_irsa_policy_attach,
  ]
}
