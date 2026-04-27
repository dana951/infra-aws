# infra-aws

Terraform infrastructure for a GitOps-based CI/CD platform on AWS EKS.

This repository is part of the larger [`eks-gitops-platform`](https://github.com/dana951/eks-gitops-platform) project.  
Its responsibility is to provision AWS networking, EKS, cluster add-ons, and core platform tooling (Jenkins + Argo CD).

## What This Repo Delivers

- Production-style VPC foundation (public/private subnets, routing, NAT).
- EKS cluster with private worker node groups dedicated to workloads.
- EKS add-ons with IRSA-based permissions:
  - `aws-ebs-csi-driver`
  - `aws-efs-csi-driver`
  - `aws-load-balancer-controller`
- Platform tools deployed by Helm:
  - Jenkins (with JCasC and Kubernetes agents)
  - Argo CD (GitOps control plane)

## Architecture at a Glance

Provisioning is split into layers (separate Terraform states) to reduce blast radius and simplify operations:

1. `vpc` - network foundation
2. `eks` - cluster, node groups, OIDC, access entries
3. `eks-addons` - CSI drivers + ALB controller
4. `eks-tools` - Jenkins + Argo CD

Why split states:
- Smaller, easier-to-review plans
- Safer changes in fast-moving layers (`eks-tools`, `eks-addons`)
- Cleaner rollback and troubleshooting boundaries

## Repository Layout

```text
infra-aws/
├── accounts/devops/
│   ├── vpc/         # VPC stack
│   ├── eks/         # EKS cluster stack
│   ├── eks-addons/  # EKS addons and related IRSA roles
│   └── eks-tools/   # Jenkins and Argo CD Helm releases
└── modules/
    ├── vpc/
    ├── eks/
    ├── eks-managed-addons/
    └── helm-release/
```

## Prerequisites

- AWS account and IAM permissions to provision networking, IAM, EKS, and Helm-related resources
- `terraform` >= 1.14.8
- `aws` CLI (with profiles configured)
- `kubectl`
- `helm`
- If using an S3/DynamoDB backend, provision those resources in advance.
- This portfolio uses local Terraform state to minimize cost and keep setup lightweight.

## Access Model (High Level)

- Terraform runs under an assumed execution role (recommended) instead of long-lived admin credentials.
- EKS access uses **EKS Access Entries** (recommended modern approach), not legacy `aws-auth` ConfigMap customization.
- Admin access for `kubectl` is done via role assumption and `aws eks update-kubeconfig`.

## Quick Start

Before running Terraform, complete IAM/profile setup in [`Detailed IAM and AWS CLI Setup`](#detailed-iam-and-aws-cli-setup).

> Run from the `infra-aws` repository root.

### 1) Provision base network

```bash
cd accounts/devops/vpc
terraform init
terraform validate
terraform plan
terraform apply
```

### 2) Provision EKS

```bash
cd ../eks
terraform init
terraform validate
terraform plan
terraform apply
```

### 3) Configure kubeconfig

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name cicd-eks \
  --profile <eks-admin-profile>  # configured in `Detailed IAM and AWS CLI Setup` -> `Configure EKS admin access role`

# Verify you can access the cluster API and list worker nodes
kubectl get nodes
```

### 4) Provision cluster add-ons

```bash
cd ../eks-addons
terraform init
terraform validate
terraform plan
terraform apply
```

### 5) Provision platform tools

```bash
cd ../eks-tools
terraform init
terraform validate
terraform plan
terraform apply
```

## Post-Deployment Validation

- Check worker nodes: `kubectl get nodes -o wide`
- Check addons and controllers:
  - `kubectl get pods -n kube-system`
- Check Jenkins namespace:
  - `kubectl get pods,svc -n jenkins`
- Check Argo CD namespace:
  - `kubectl get pods,svc -n argocd`

For local access in this portfolio environment, use port-forward:

```bash
kubectl port-forward svc/jenkins -n jenkins 8085:8080
kubectl port-forward svc/argocd-server -n argocd 8086:80
```

Production-grade access pattern (instead of port-forward):
- Expose Jenkins and Argo CD through Kubernetes `Ingress` resources.
- Use the AWS Load Balancer Controller to provision an ALB from those ingress definitions.
- Use host-based routing rules (for example `jenkins.<domain>` and `argocd.<domain>`).
- Manage DNS in Route53 with a pre-owned domain/subdomains mapped to the ALB.
- Terminate TLS with ACM certificates attached via ingress annotations.

## Known Limitation

#### Argo CD CRD plan-time validation in Terraform

`eks-tools` currently includes both:
- Argo CD Helm installation
- a `kubernetes_manifest` for an Argo CD `Application`

Terraform validates `kubernetes_manifest` schema during **plan**, but Argo CD CRDs are created only when Helm is **applied**.  
This can cause plan failure (`no matches for kind "Application" in group "argoproj.io"`).

Recommended production approach:
- Keep Argo CD Helm install in `eks-tools`
- Move Argo CD `Application` resources to a separate state/repo executed after CRDs exist

## Detailed IAM and AWS CLI Setup

This section defines the IAM identities and AWS profiles used by this repository.

### 1) Create bootstrap IAM identities

- Create IAM user: `terraform-user` (programmatic access).
- Create IAM group: `terraform`.
- Add `terraform-user` to `terraform` group.

### 2) Create Terraform execution role

- Create IAM role: `TerraformExecutionRole`.
- Use a trust policy that allows your account to assume the role (optionally enforce `ExternalId`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR_ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "YOUR_EXTERNAL_ID_SECRET"
        }
      }
    }
  ]
}
```

Attach permissions to `TerraformExecutionRole`:
- `AmazonVPCFullAccess`
- `AmazonEC2FullAccess`
- `CloudWatchLogsFullAccess`
- `TerraformEKSFullAccess` (custom policy for EKS lifecycle operations)
- `TerraformIAMForEKSPolicy` (custom IAM policy for EKS-related IAM operations, including restricted `iam:PassRole` and `iam:CreateServiceLinkedRole`)

Custom policy definitions used in this setup:

`TerraformEKSFullAccess`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformEKSFullAccess",
      "Effect": "Allow",
      "Action": "eks:*",
      "Resource": "*"
    }
  ]
}
```

`TerraformIAMForEKSPolicy`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IAMPermissionsForTerraformEKS",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfiles",
        "iam:ListInstanceProfilesForRole",
        "iam:CreateOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider",
        "iam:GetOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "iam:CreatePolicy",
        "iam:TagPolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:DeletePolicy"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CreateEKSServiceLinkedRole",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/aws-service-role/*",
      "Condition": {
        "StringLike": {
          "iam:AWSServiceName": [
            "eks.amazonaws.com",
            "eks-nodegroup.amazonaws.com",
            "eks-fargate.amazonaws.com",
            "elasticloadbalancing.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "PassEksClusterRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-master-role",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "eks.amazonaws.com"
        }
      }
    },
    {
      "Sid": "PassEksNodeGroupRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-nodegroup-role",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "eks.amazonaws.com"
        }
      }
    },
    {
      "Sid": "PassEksEBSCSIDriverRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/aws-ebs-csi-driver-addon-irsa-role",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "eks.amazonaws.com"
        }
      }
    },
    {
      "Sid": "PassEksEFSCSIDriverRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/aws-efs-csi-driver-addon-irsa-role",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "eks.amazonaws.com"
        }
      }
    }
  ]
}
```

Notes:
- `eks-master-role` and `eks-nodegroup-role` are created during EKS cluster provisioning.
- `aws-ebs-csi-driver-addon-irsa-role` and `aws-efs-csi-driver-addon-irsa-role` are created when provisioning the EBS/EFS CSI add-ons.

Add this inline policy to `terraform` group so `terraform-user` can assume `TerraformExecutionRole`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAssumeTerraformExecutionRole",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/TerraformExecutionRole"
    }
  ]
}
```

### 3) Configure AWS profile for Terraform runs

Configure base credentials:

```bash
aws configure --profile terraform-user
```

Add assumed-role profile in `~/.aws/config`:

```ini
[profile devops]
role_arn       = arn:aws:iam::YOUR_ACCOUNT_ID:role/TerraformExecutionRole
source_profile = terraform-user
region         = us-east-1
output         = json
# duration_seconds = 7200
# external_id = YOUR_EXTERNAL_ID_SECRET
```

If using `duration_seconds = 7200`, also update the IAM role setting in AWS:
`IAM -> Roles -> TerraformExecutionRole -> Edit -> Max session duration -> 2 hours`.

Verify:

```bash
aws sts get-caller-identity --profile devops
```

### 4) Configure EKS admin access role (for kubectl and AWS Console visibility)

- Create IAM role: `DevopsAdminRole`.
- Attach policy: `AdministratorAccess` (portfolio setup).
- Create admin user: `devops-admin` and place it in `admins` group (console user that can view EKS resources in AWS Console, and base profile for role assumption).
- Allow `admins` group to assume `DevopsAdminRole` with an inline policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAssumeDevopsAdminRole",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/DevopsAdminRole"
    }
  ]
}
```

Configure AWS CLI profiles for cluster administration:

```bash
aws configure --profile admin
```

```ini
[profile eks-admin]
role_arn       = arn:aws:iam::YOUR_ACCOUNT_ID:role/DevopsAdminRole
source_profile = admin
region         = us-east-1
output         = json
# duration_seconds = 7200
```

If using `duration_seconds = 7200`, also update:
`IAM -> Roles -> DevopsAdminRole -> Edit -> Max session duration -> 2 hours`.

### 5) EKS Access Entry mapping

The EKS layer maps `DevopsAdminRole` and `TerraformExecutionRole` to the EKS cluster admin policy using **EKS Access Entries** (`AmazonEKSClusterAdminPolicy`), which is the modern replacement for direct `aws-auth` management.


## Further Reading

### Project Repositories

- Platform umbrella project: [`eks-gitops-platform`](https://github.com/dana951/eks-gitops-platform)
- GitOps apps repo used by Argo CD: [`argocd-apps`](https://github.com/dana951/argocd-apps)

### AWS / Kubernetes Documentation

- [Amazon EKS access entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
- [Amazon EKS add-ons](https://docs.aws.amazon.com/eks/latest/userguide/workloads-add-ons-available-eks.html)
- [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
- [Jenkins Configuration as Code](https://www.jenkins.io/projects/jcasc/)
- [Argo CD - App of Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)

