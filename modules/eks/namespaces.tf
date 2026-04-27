resource "kubernetes_namespace_v1" "environments" {
  for_each = var.namespaces

  metadata {
    name = each.value
  }

  depends_on = [
    aws_eks_cluster.eks_cluster, 
    aws_eks_access_policy_association.cluster_admin_roles
    # Ensure namespaces are destroyed BEFORE access entries are removed
  ]
}
 