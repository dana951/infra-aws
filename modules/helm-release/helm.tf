resource "helm_release" "release" {
  for_each = local.enabled_helm_charts

  name                = each.key
  namespace           = each.value.namespace
  repository          = each.value.repository
  chart               = each.value.chart
  version             = each.value.chart_version
  create_namespace    = each.value.create_namespace
  values              = each.value.values
  set_sensitive       = each.value.set_sensitive
  wait                = each.value.wait
  timeout             = each.value.timeout
  atomic              = each.value.atomic
  cleanup_on_fail     = each.value.cleanup_on_fail
  dependency_update   = each.value.dependency_update

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

  depends_on = [
    aws_iam_role_policy_attachment.helm_chart_irsa_policy_attach,
  ]
}
