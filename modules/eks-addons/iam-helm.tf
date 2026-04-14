locals {
  enabled_helm_charts = {
    for release_name, chart in var.helm_charts : release_name => chart
    if chart.enabled
  }

  helm_charts_with_irsa = {
    for release_name, chart in local.enabled_helm_charts : release_name => chart
    if try(chart.irsa, null) != null
  }
}

resource "aws_iam_role" "helm_chart_iam_role" {
  for_each = local.helm_charts_with_irsa

  name = "${each.key}-helm-irsa-role"

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
            "${var.oidc_issuer_hostpath}:sub" = "system:serviceaccount:${try(each.value.namespace, "default")}:${each.value.irsa.k8s_service_account}"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-${var.cluster_name}-${each.key}-helm-irsa-role"
    },
  )
}

data "http" "helm_chart_policy_document" {
  for_each = local.helm_charts_with_irsa

  url = each.value.irsa.policy_document_url
}

resource "aws_iam_policy" "helm_chart_irsa_policy" {
  for_each = local.helm_charts_with_irsa

  name   = "${each.key}-helm-irsa-policy"
  policy = data.http.helm_chart_policy_document[each.key].response_body

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-${var.cluster_name}-${each.key}-helm-irsa-policy"
    },
  )
}

resource "aws_iam_role_policy_attachment" "helm_chart_irsa_policy_attach" {
  for_each = local.helm_charts_with_irsa

  role       = aws_iam_role.helm_chart_iam_role[each.key].name
  policy_arn = aws_iam_policy.helm_chart_irsa_policy[each.key].arn
}
