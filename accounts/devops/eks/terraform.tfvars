aws_region = "us-east-1"
profile    = "devops"

name_prefix  = "devops"
cluster_name = "cicd-eks"
cluster_version = "1.35"

cluster_service_ipv4_cidr = "172.20.0.0/16"

cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true
cluster_endpoint_public_access_cidrs = []

private_node_groups = {
  jenkins = {
    min_size     = 1
    max_size     = 1
    desired_size = 1
    tags = {
      NodeGroup = "jenkins"
    }
  }
  jenkins-agents = {
    min_size     = 1
    max_size     = 1
    desired_size = 1
    tags = {
      NodeGroup = "jenkins-agents"
    }
  }
}

public_node_groups = {}

common_tags = {
  Project     = "devops-portfolio"
  Environment = "devops"
  ManagedBy   = "terraform"
  Component   = "eks-platform"
}
