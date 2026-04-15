resource "aws_iam_role" "addon_iam_role" {
  for_each = local.enabled_addons

  name = "${each.key}-irsa-role"

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
            "${var.oidc_issuer_hostpath}:sub" = "system:serviceaccount:kube-system:${each.value.irsa.k8s_service_account}"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-${var.cluster_name}-${each.key}-irsa-role"
    },
  )
}

resource "aws_iam_role_policy_attachment" "addon_irsa_policy_attach" {
  for_each = local.enabled_addons

  role       = aws_iam_role.addon_iam_role[each.key].name
  policy_arn = each.value.irsa.policy_arn
}
