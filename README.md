# infra-aws
WIP - Infrastructure provisioning for a production-grade EKS cluster hosting a GitOps-based CI/CD platform (Jenkins/argocd)

This repository is part of the [**eks-gitops-platform**](https://github.com/dana951/eks-gitops-platform) project - GitOps CI/CD workflow on AWS EKS. 

##################################################

terraform code for provision and managing infrastructure on AWS 

# Pre-requisite: Should have AWS Account, aws cli, terraform, kubectl
### bootstrap
(s3, dynamodb, iam user/group/role)

##### S3 + DynamoDB (for state file backend)
- create `S3` bucket with versioning and encryption enabled
- create `DynamoDB` table (LockID)

##### IAM
- Create `terraform user` (with progrematic credentials)
- Create `terraform group` - Add the `terraform user` to this group
- create `terraform role` (TerraformExecutionRole), preferable with external_id
trust policy:
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

role Permissions policies
- AmazonVPCFullAccess
- AmazonEC2FullAccess
- CloudWatchLogsFullAccess  (for eks cluster log group in cloudwatch)
- TerraformIAMForEKSPolicy (custome policy, with iam related permission and restrictive 
                            iam:PassRole permission, description below, and CreateEKSServiceLinkedRole statement - see below)
- TerraformEKSFullAccess    (custome policy, eks:*, to allow terraform full eks access - see below)


- Add `terraform group` inline policy - to allow assume the TerraformExecutionRole
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

##### AWS Configure
1. aws configure --profile terraform-user
provide terraform user access key and secret access key (this is the "base" profile)

2. edit ~/.aws/config
[profile devops]
role_arn         = arn:aws:iam::YOUR_ACCOUNT_ID:role/TerraformExecutionRole
source_profile   = terraform-user
# duration_seconds = 7200   # If ned to change the Role max session duration (default 1 hour), then in IAM also need to configure  IAM → Roles → TerraformExecutionRole → Edit → Max session duration → 2 hours
# external_id      = YOUR_EXTERNAL_ID_SECRET (if TerraformExecutionRole has external_id condition in its' trust policy)
output = json

3. verify assume role successfully
# aws sts get-caller-identity --profile devops

4. Role for EKS access (EKS Access Entry)
- Create `DevopsAdminRole` Role with AdministratorAccess policy (used in EKS Access Entry - see below)
`devops-admin` user (the account admin) --> in admins group --> AdministratorAccess policy directly on the group (to not need to switch role when ever login to console, in production use idp + role)

5. Allow `devops-admin` user to assume this `DevopsAdminRole` Role
devops-admin  --> in admins group --> Role "DevopsAdminRole"  with AdministratorAccess policy    
- so when devops-admin login to the aws console --> in order to be able to see k8s resources in EKS --> need to switchrole in the aws console to "DevopsAdminRole"

group inline policy
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

EKS Access Entry:
in the eks cluster we configure access_entry mapping `DevopsAdminRole` IAM Role to `AmazonEKSClusterAdminPolicy` cluster access policy 
(An EKS Access Entry is a native Amazon EKS feature that allows to grant AWS Identity and Access Management (IAM) principals (users or roles) permissions to the Kubernetes cluster directly via the Amazon EKS API. 
This modern method serves as the recommended alternative to the now-deprecated `aws-auth` ConfigMap.)

# provision order

- vpc  # Provision VPC, IGW, 1 NAT GW, 1 EIP, 3 public subnets, 3 private subnets, 1 public Route table, 1 private Route table
- eks  # Provision EKS cluster, access entry (`DevopsAdminRole` IAM Role --> mapped to `AmazonEKSClusterAdminPolicy` cluster access policy), 3 private nodes groups `jenkins` private node group for `jenkins`, `argocd`, `jenkins-agents` private node group for jenkins build pod agents and `podinfo-app` private node group for podinfo app, IAM OIDC Provider for the EKS Cluster IDP, EKS Control Plan Role, EKS Data Plan Role (worker nodes), CloudWatch logs,
endpoint_private_access enabled , endpoint_public_access (need to be disabled, use bastion host)
- eks-addons (EBS CSI Driver, EFS CSI Driver, AWS Load Balancer Controller)
- eks-tools (jenkins, argocd)

### Why we use multiple Terraform state files
This repository intentionally separates state by layer (`vpc`, `eks`, `eks-addons`, `eks-tools`) instead of using one large shared state file.

Benefits:
- **Safer changes (smaller blast radius):** updates to fast-changing layers (addons/tools) cannot accidentally impact foundational layers (VPC/EKS).
- **Cleaner operations:** smaller plans are easier to review, troubleshoot, and roll back.

Provisioning follows dependency order: `vpc` -> `eks` -> `eks-addons` -> `eks-tools`.

Provision the VPC
# cd infra-aws/accounts/devops/vpc
# terraform init
# terraform validate
# terraform plan
# terraform apply

Provision EKS Cluster
# cd infra-aws/accounts/devops/eks
# before provision set your ip in terraform.tfvars e.g cluster_endpoint_public_access_cidrs = ["<your_ip>/32"]
(public access need to be disabled, use bastion host or other way privatly accessing the cluster endpoint)
# terraform init
# terraform validate
# terraform plan
# terraform apply

# update `~/.kube/config` to allow interacting with the cluster via kubectl
First configure the admin user and allow it to assume the DevopsAdminRole
(we Provision EKS cluster with access entry (`DevopsAdminRole` IAM Role --> mapped to `AmazonEKSClusterAdminPolicy` cluster access policy, this replaces the old-style aws-auth configmap)

in IAM - create progrematic creadentials for the devops-admin user
and set those creds
# aws configure --profile admin
Now add assume role config
# vim ~/.aws/config
[profile eks-admin]
role_arn         = arn:aws:iam::YOUR_ACCOUNT_ID:role/DevopsAdminRole
source_profile   = admin
region           = us-east-1
# duration_seconds = 7200   # then in iam also need to configure (default 1 hour) IAM → Roles → DevopsAdminRole → Edit → Max session duration → 2 hours
output = json

update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name cicd-eks --profile eks-admin

Verify you can reach the cluster
# kubectl get nodes

# Provision EKS Addon # EBS CSI Driver, AWS Load Balancer Controller (EBS for jenkins persistance, EBS is AZ related, in production need to take backup (snapshot) or concidre using EFS CSI driver for multi AZ access in case jenkins get reschedule in a node in another AZ)
# cd infra-aws/accounts/devops/eks-addons
# terraform init
# terraform validate
# terraform plan
# terraform apply

# Provision EKS tools (jenkins, argocd) - see comment below regarding provision argocd helm chart + argocd Application manifests inn the same terraform run
# cd infra-aws/accounts/devops/eks-tools
# terraform init
# terraform validate
# terraform plan
# terraform apply

For POC we will do port-forward to access jenkins UI, in production we will 
provision load balancer (see ALB below)

kubectl port-forward svc/jenkins -n jenkins 8085:8080
login creadentials
user: admin
for password run:
kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
http://localhost:8085/

kubectl port-forward svc/argocd-server -n argocd 8086:80
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
http://localhost:8086/


Note - ALB
 we installed the AWS Load Balancer Controller
For This POC, to reach jenkins and argocd we will use `kubectl port-forward`
in real production environment we will provision ALB via the AWS Load balancer controller, and Dynamically assign DNS using DNS controller and ssl by annotating the ingress related setting in the jenkins and argocd values file (helm) and configure host based routing 
(we need predefined domain name to be set in Route53 for custom DNS for the ALB)
and we will also need to configure Security group to access the ALB, and Security Group allow the ALB to access the worker nodes 

Note - Secret Manager (for jenkins secrets)
- For security - we can povision AWS secret manager and install secret manager plugin to jenkins 
to allow jenkins save and retrive secrets securily from Secret Manager , also need to provide the needed IAM Permission in the IRSA Role for jenkins to access secret manager




Open Issues
# ToDo
Terraform Plan-Time CRD Validation
when cd to eks-tool and run terraform plan
we get error while terraform try to provision argocd main app manifests
(kubernetes_manifest.argocd_main_app)
the problem:
When Terraform plans a kubernetes_manifest resource, it validates the manifest schema against the live cluster at plan time — before any resources are applied.
ArgoCD CRDs (Application, AppProject, etc.) are installed by the ArgoCD Helm chart at apply time.
This creates an unresolvable conflict in a single Terraform run:
PLAN TIME:
  kubernetes_manifest "argocd_main_app"
    → validates "Application" CRD against cluster
    → CRD doesn't exist yet
    → ❌ Error: no matches for kind "Application" in group "argoproj.io"

APPLY TIME:
  helm_release "argocd"
    → installs ArgoCD
    → CRDs now exist ✅ (too late)
depends_on does not solve this — it controls apply order only, not plan-time validation.
Solution: Split Into Separate Terraform States
eks-tools/   → installs ArgoCD Helm chart (CRDs created here)
argocd-app/     → creates ArgoCD Applications (CRDs already exist)
By the time eks-apps runs, the CRDs are live in the cluster, so kubernetes_manifest plan-time validation succeeds.


# destroy
# terraform plan -destroy
# terraform apply -destroy



# terraform state commands
# terraform state list
# terraform show






# vpc module consume --> number of private subnets == number of public subnets
# and at least 2 private subnets in 2 different AZ (this is for the )


aws_eks_cluster
vpc_config Arguments
subnet_ids - (Required) List of subnet IDs. Must be in at least two different availability zones. Amazon EKS creates cross-account elastic network interfaces in these subnets to allow communication between your worker nodes and the "aws_eks_cluster" --> vpc_config --> subnet_ids (the ENI cross account of the EKS that is in our VPC to reach the eks control plan in AWS VPC)


variable "namespaces" {
  type        = list(string)
  description = "Namespaces to create after EKS bootstrap."
  default     = ["jenkins", "jenkins-agents", "argocd", "monitoring"]
}


# https://docs.aws.amazon.com/eks/latest/userguide/workloads-add-ons-available-eks.html
aws-efs-csi-driver

resource "aws_eks_addon" "ebs_eks_addon" {
  depends_on = [ aws_iam_role_policy_attachment.efs_csi_iam_role_policy_attach]
  cluster_name = var.cluster_name 
  addon_name   = "aws-efs-csi-driver"
  service_account_role_arn = aws_iam_role.efs_csi_iam_role.arn 
}

aws eks describe-addon-versions \
    --addon-name aws-efs-csi-driver \
    --kubernetes-version <your-eks-version> \
    --query 'addons[].addonVersions[].addonVersion'


notes
1. TerraformIAMForEKSPolicy 
- this is custome policy to create which allow iam related operations when terrafromr manages the EKS cluster lifecycle (including restrictive iam:PassRole permission).
iam:PassRole permission - we use role names terraform will provision fir the eks-cluster controle plan to use and for the eks node group to use

here i decided to not use var.name-prefix in aws_iam_role resource so eks cluster control plan role and node group role will be fixed names (because the policy with the iam:PassRole was pre provisioned in aws manually)
eks cluster role name: eks-master-role


so need to correlate between those 2 roles names we use in this custome policy when we create in manually and the names of the roles we use in our terraform code (with the name-prefix variable "devops")
- devops-eks-master-role (this is the iam role terraform will create and that will be used by the eks cluster control plan)
- devops-eks-nodegroup-role (this is the iam role terraform will create and that will be used by the eks cluster node groups)

- CreateEKSServiceLinkedRole statement in the "TerraformIAMForEKSPolicy" policy
A Service Linked Role is a special IAM role that an AWS service creates for itself, so it can call other AWS services on your behalf.
hen you run terraform apply and create an EKS cluster for the first time in your AWS account, that service linked role may not exist yet. EKS will try to create it automatically — but Terraform is making the API call, so Terraform's role needs permission to create it.
Once created, it lives in your account forever and this permission is rarely needed again.
The Flow
When you call eks:CreateCluster, EKS internally tries to create its own service linked role. But that creation is an IAM API call — specifically iam:CreateServiceLinkedRole.
The question is: whose credentials are used for that IAM call?
The Answer
Terraform's credentials.
Even though EKS is the one that "wants" to create the service linked role, the API call happens within the context of your terraform apply, using Terraform's IAM identity (TerraformExecutionRole).
So the flow is:
Terraform (TerraformExecutionRole)
    → calls eks:CreateCluster
        → EKS internally calls iam:CreateServiceLinkedRole
            → but this call is made using YOUR credentials (TerraformExecutionRole)
                → fails if TerraformExecutionRole lacks iam:CreateServiceLinkedRole

2. iam permission
Real techniques used in companies
✅ Method 1 — Start broad, then reduce (MOST COMMON)
Start with:
ec2:*, eks:*, etc.
Run Terraform
Use:
CloudTrail
AWS IAM Access Analyzer
Generate used permissions
Replace with minimal set
✅ Method 2 — Use AWS “last accessed” data
IAM → Access Advisor shows:
Which actions were actually used
✅ Method 3 — Use policy generation tools
Tools like:
AWS Access Analyzer (policy generation)
Terraform plan logs
CloudTrail logs
✅ Method 4 — Trial & error (yes, really)
They:
Remove permissions gradually
Re-run Terraform
Fix failures
👉 This is extremely common
⚠️ Important reality:
Nobody writes perfect least-privilege from scratch.
It’s always:
Iterate → observe → reduce
✅ 3. Do these tools cost money?
CloudTrail	        ✅ Free (basic) / 💰 Paid (advanced)
Access Advisor	    ✅ Free
IAM Access Analyzer	✅ Mostly free



3. aws cli --> [profile devops-eks] to assume DevopsAdminRole 
How You Use It Day to Day
AWS Console access — you log in as devops-admin normally. You see everything because AdministratorAccess is on your group. No role switching needed for normal AWS console usage.
kubectl access — you assume DevOpsTeamRole only when you need to interact with Kubernetes. You add one profile to ~/.aws/config:
ini

[profile devops-eks]
role_arn       = arn:aws:iam::ACCOUNT_ID:role/DevOpsTeamRole
source_profile = devops-admin-user
region         = us-east-1
duration_seconds = 3600

Then update kubeconfig once:

bashaws eks update-kubeconfig \
  --name devops-eks \
  --region us-east-1 \
  --profile devops-eks
Now kubectl uses DevOpsTeamRole automatically. AWS console uses devops-admin directly. Two separate tools, two separate profiles, zero role switching in the console.



# aws-auth configmap
when ever we create the EKS Cluster —> it does not create any aws-auth Config for usbut when ever we create our first EKS node group , so currently we create one public node group, and for that respective node group with worker nodes, whenever we create that we create an EKS node group Role —> so that node group Role will get automatically updated inside this MapRole section in aws-auth ConfigMap, so whenever we create node group, at that point in time, whatever that node group Role is going to have, that is going to get updated in the aws-auth ConfigMap

resource "aws_eks_access_entry" "devops_team" {
  cluster_name      = aws_eks_cluster.cluster.name
  principal_arn     = "arn:aws:iam::ACCOUNT_ID:role/DevOpsTeamRole"
  kubernetes_groups = ["system:masters"]
  type              = "STANDARD"
}

# kubectl auth can-i --list
This is one of the most important debugging tools.
👉 It asks Kubernetes:
“What am I allowed to do?”
👉 Shows ALL permissions you currently have
example:
Resources                                       Non-Resource URLs   Resource Names   Verbs
pods                                            []                  []               [get list    
                                                                                    create delete]
deployments.apps                                []                  []               [get list 
                                                                                      create update]
namespaces                                      []                  []               [get list]

example:
kubectl auth can-i create pods
output:
yes
Why it’s important here
👉 Because with Access Entries:
You CANNOT see RBAC objects
BUT you CAN verify permissions this way
So:
This is your only reliable way to “see” what AWS policies gave you





# steps
1. provision VPC
Clone the infra-aws repo
- git clone https://github.com/dana951/infra-aws.git


- cd infra-aws/accounts/devops/vpc/

- run terraform
  - terraform init 
  - terraform validate 
  - terraform plan
  - terraform apply

2. provision EKS
- cd infra-aws/accounts/devops/eks-platform/

- run terraform
  - terraform init 
  - terraform validate 
  - terraform plan
  - terraform apply 



# EFS csi driver add on instruction
you are expert senior devops engineer, you are expert in aws, eks, terraform. 
i am a devops engineer and i am implementing a devops portfolio project to apply for a devops jobs.
i started to implement the project
you will be my mentor, my devops expert guid , you will help me implement this devops project.
you write clear, clean, readable, well structured, proffesional, senior level terraform code.

lets take it step by step

now i want to add new module under the infra-aws/modules

the module name need to be "eks-addons"
please add to this module
- EFS csi driver add on (aws_eks_addon).
some information from the official aws eks add-ons docs regarding the
"Amazon EFS CSI driver" can be found in this link
see the comment there "For Amazon EFS file systems only: Attach the AmazonEFSCSIDriverPolicy managed policy"

https://docs.aws.amazon.com/eks/latest/userguide/workloads-add-ons-available-eks.html#add-ons-aws-efs-csi-driver 
create role with the relevant policy for irsa for this efs csi driver

creat variables.tf, outputs.tf, versions.tf (see example from modules/eks)



# helm cmmands

helm repo list

helm plugin list

helm list 
(only shows the current namespace)

helm list -A
(show ALL releases across ALL namespaces)

########
# EKS - ALB
########

# helm repo add eks https://aws.github.io/eks-charts

# helm repo update eks

# helm search repo eks/aws-load-balancer-controller --versions | head -5

# helm pull eks/aws-load-balancer-controller --version 3.2.1 --untar --untardir /Users/dana/devops_workspace/devops-portfolio/delete-this/helm-charts


# helm show values eks/aws-load-balancer-controller --version 3.2.1 > /Users/dana/devops_workspace/devops-portfolio/delete-this/loab-balancer/load-balancer-default-values.yaml

# helm template alb eks/aws-load-balancer-controller --version 3.2.1 --namespace kube-system -f <values-file> > <folder>/<filename>

##############
# agrocd
############

# helm repo add argo https://argoproj.github.io/argo-helm

# helm repo update argo

# helm search repo argo/argo-cd --versions | head -5

# helm show values argo/argo-cd --version 9.5.2 /tmp/argocd-default-values.yaml

# helm template argo argo/argo-cd --version 9.5.2 --namespace argocd > /Users/dana/devops_workspace/devops-portfolio/delete-this/templates/argocd/argo.yaml

# helm pull argo/argo-cd --version 9.5.2 --untar --untardir /Users/dana/devops_workspace/devops-portfolio/delete-this/helm-charts

# helm install argocd argo/argo-cd --version 9.5.2 --namespace argocd --create-namespace

# kubectl port-forward service/argocd-server -n argocd 8081:443

# http://localhost:8081

admin
RAuc9qWKrnwdSsx2

##############
# jenkins
############

# helm repo add jenkins https://charts.jenkins.io

# helm repo update jenkins

# helm search repo jenkins/jenkins --versions | head -5

# helm show values jenkins/jenkins --version 5.9.14 > /tmp/jenkins-default-values.yaml

# helm template jenkins jenkins/jenkins --version 5.9.14 --namespace jenkins > /Users/dana/devops_workspace/devops-portfolio/delete-this/templates/jenkins/jenkins.yaml

# helm pull jenkins/jenkins --version 5.9.14 --untar --untardir /Users/dana/devops_workspace/devops-portfolio/delete-this/helm-charts

# helm install jenkins jenkinsci/jenkins --version 5.9.14 --namespace jenkin --create-namespace

# kubectl port-forward service/jenkins-1 8080:8080

admin
YdKkPEUVlJm28BMhOddxf0


kubectl apply -f https://raw.githubusercontent.com/dana951/argocd-apps/main/main-app.yaml

kubectl get app -n argocd

kubectl get appset -n argocd

kubectl get appproj -n argocd

# Identify CRDs: To see all available Argo CD resource types, run:
kubectl api-resources | grep argoproj
---------
kind
---------
# kind create cluster --name k8s-cluster
(i see that kind updated ~/.kube/config)

# kind get clusters
(my cluster name - k8s-cluster)

# kind get kubeconfig -n k8s-cluster

# kind get nodes

# kubectl cluster-info
# kubectl get nodes

# kubectl create namespace jenkins

# helm install jenkins jenkins/jenkins --version 5.9.14 --namespace jenkins
Or create namespace also
# helm install jenkins jenkins/jenkins --version 5.9.14 --namespace jenkins --create-namespace

# kubectl get pods -n jenkins
# kubectl get svc -n jenkins

# kubectl --namespace jenkins port-forward svc/jenkins-1 8080:8080

admin
YdKkPEUVlJm28BMhOddxf0

# Configuration as Code
http://127.0.0.1:8080/configuration-as-code

-------------------
jenkins
-------------------
# helm install jenkins-1 jenkins/jenkins --version 5.9.14 --namespace jenkins
1. Get your 'admin' user password by running:
  kubectl exec --namespace jenkins -it svc/jenkins-1 -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  echo http://127.0.0.1:8080
  kubectl --namespace jenkins port-forward svc/jenkins-1 8080:8080

3. Login with the password from step 1 and the username: admin
4. Configure security realm and authorization strategy
5. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http://127.0.0.1:8080/configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine

For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/


NOTE: Consider using a custom image with pre-installed plugins



# https://plugins.jenkins.io/

plugin: AWS Secrets Manager Credentials Provider --> need IAM role (via IRSA) 
(No direct values.yaml magic—this is plugin + IAM setup)


-------------------------------
Argo
-------------------------------
Danas-MacBook-Pro:udemy-repos dana$ helm install argocd argo/argo-cd --version 9.5.2 --namespace argocd --create-namespace
NAME: argocd
LAST DEPLOYED: Mon Apr 20 12:17:17 2026
NAMESPACE: argocd
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
In order to access the server UI you have the following options:

1. kubectl port-forward service/argocd-server -n argocd 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress in the values file `server.ingress.enabled` and either
      - Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
      - Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts


After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)
Danas-MacBook-Pro:udemy-repos dana$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


------
docker hub
______
devuser103
BaLiMasheoTaeim135!

cat ~/.docker/config.json

docker login -u devuser103 -p BaLiMasheoTaeim135!

docker build -t devuser103/podinfo:0.1.0 .

docker push devuser103/podinfo:0.1.0



------
podinfo
------

# cd gitops-manifests

# helm install podinfo ./podinfo --namespace podinfo --create-namespace 

# helm install podinfo ./podinfo --namespace podinfo --create-namespace --set env.THEME_COLOR=yellow

# helm list -A

# kubectl port-forward service/podinfo-podinfo -n podinfo  8083:80

# http://localhost:8083/


# helm uninstall podinfo -n podinfo

# kubectl delete namespace podinfo
(Optionally delete the namespace too)

# helm history podinfo -n podinfo

# helm status podinfo -n podinfo

# helm status podinfo -n podinfo --revision 1

# helm show chart podinfo



# CI/CD
branch strategy is GitHub Flow
What it is                     What it is NOT
main is always deployable      No long-lived develop branchFeature branches off main (feature/add-health-check)     No release/* branches
PR → review → merge to main    No hotfix/* branches (just branch off main)
Merge to main = triggers       No manual version bumping
deployment pipeline

in real case:
Approach 2
Self-hosted GHA runner inside your cluster (modern, elegant)
Self-hosted GHA Runner (runs as a Pod in EKS) has private network access   
to Jenkins, ArgoCD, ECR 
You deploy a self-hosted GitHub Actions runner inside your EKS cluster. This runner registers itself with GitHub (outbound connection only). When GHA schedules a job on it, the runner pulls the job and executes it — with full access to your private network. 
Tools: actions/runner deployed as a Kubernetes Deployment, or Actions Runner Controller (ARC) for auto-scaling runners.

Approach 3: Message queue / event bus (enterprise scale) ✅✅✅
GHA → publishes event → SQS / SNS / EventBridge
                              │
                    Jenkins polls queue (outbound)
                              │
                    Jenkins picks up job
GHA publishes a message to an AWS SQS queue. Jenkins (inside private network) polls SQS — outbound only. No exposure.
Pros: Fully decoupled. Retry logic built in. Audit trail in the queue. Works even if Jenkins is briefly down.
Cons: More infrastructure. Overkill for smaller setups.
When companies use it: Large enterprises with strict zero-trust networking.


Setup Steps
Docker Hub workflow
One-time setup — 3 steps:
1. Create a Docker Hub Access Token
Go to hub.docker.com → Account Settings → Security → New Access Token. Name it github-actions-podinfo. Permission: Read & Write. Copy the token — you only see it once.
2. Add secrets to your GitHub repo
Go to your app-source repo → Settings → Secrets and variables → Actions → New repository secret:

DOCKERHUB_USERNAME → your Docker Hub username (e.g. devuser103)
DOCKERHUB_TOKEN → the access token you just created

3. That's it. The workflow uses docker/login-action which handles the rest.

ECR workflow — Public GHA runners (OIDC, recommended)
This is the modern approach — no static AWS keys anywhere.
Step 1: Add GitHub as an OIDC identity provider in AWS
Go to AWS Console → IAM → Identity Providers → Add Provider:

Provider type: OpenID Connect
Provider URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com

Click Get thumbprint, then Add provider.
Step 2: Create an IAM role for GitHub Actions
Go to IAM → Roles → Create Role:

Trusted entity type: Web identity
Identity provider: token.actions.githubusercontent.com
Audience: sts.amazonaws.com

Add a condition to restrict which repo can assume this role (critical — without this, any GitHub repo could assume your role):
json{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/app-source:*"
  }
}
Attach this inline policy (ECR push permissions only — least privilege):
json{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:us-east-1:YOUR_ACCOUNT_ID:repository/podinfo"
    }
  ]
}
Name the role github-actions-podinfo.
Step 3: Create the ECR repository
bashaws ecr create-repository --repository-name podinfo --region us-east-1
Step 4: Add one secret to GitHub

AWS_ROLE_ARN → arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-podinfo

That's all. No AWS_ACCESS_KEY_ID, no AWS_SECRET_ACCESS_KEY anywhere.

ECR workflow — Self-hosted runners (inside EKS)
With a self-hosted runner running as a Pod inside EKS, you don't need OIDC tokens or any secrets at all. The runner inherits the IAM role of the EKS node (or Pod via IRSA).
Step 1: Create an IAM policy with the same ECR permissions listed above.
Step 2: Attach via IRSA (recommended) or Node IAM role
IRSA (IAM Roles for Service Accounts) is cleaner — it scopes the permission to the runner Pod only, not the entire node:
bash# Create IAM role linked to the runner's service account
eksctl create iamserviceaccount \
  --name github-runner \
  --namespace actions-runner-system \
  --cluster YOUR_CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/ecr-push-podinfo \
  --approve
Step 3: Change runs-on in the workflow
yamlbuild-and-push:
  runs-on: self-hosted   # ← instead of ubuntu-latest
Step 4: Remove the OIDC permission block and the configure-aws-credentials step entirely — the runner already has AWS credentials via its IAM role. The amazon-ecr-login step works directly.
The key difference between the two approaches:
                           Public runner + OIDC         Self-hosted runner + IRSA
AWS credentials            Short-lived token via OIDC   Inherited from Pod IAM role
GitHub secret needed       AWS_ROLE_ARN                 None
Network access to ECR      Public ECR endpoint          Can use VPC endpoint
Setup complexity           Medium (IAM OIDC provider)   Medium (IRSA)
Best for                   Simplicity,no cluster needed Private infra,  VPC-only ECR


How the 3-step Jenkins API flow works
Job 4 in GHA
    │
    ├─ Step 1: POST /job/podinfo-deploy/buildWithParameters
    │          → Jenkins returns HTTP 201
    │          → Location: http://jenkins/queue/item/42/
    │
    ├─ Step 2: GET /queue/item/42/api/json  (every 5s, max 5min)
    │          → executable: null           → still waiting for executor
    │          → executable.url: ".../15/" → build started, got number
    │
    └─ Step 3: GET /job/podinfo-deploy/15/api/json  (every 15s, max 10min)
               → result: null     → still running, keep polling
               → result: SUCCESS  → exit 0 → GHA job ✅
               → result: FAILURE  → exit 1 → GHA job ❌
The GHA workflow run only goes green if Jenkins also went green. One status, visible in GitHub, covering the entire delivery pipeline.
Two things to note about the composite action
python3 is used for JSON parsing instead of jq — python3 is always available on any runner (public or self-hosted). jq is available on ubuntu-latest but not guaranteed on self-hosted runners. Since job 4 runs on self-hosted, python3 is the safer choice.
The job-parameters input is multi-line — you pass all Jenkins parameters as KEY=VALUE lines in a single input block. The action loops over them and builds the --data-urlencode flags dynamically, so you never have to touch the action itself when you add or change parameters.


# black
uv run black .




##################################################
## Jenkins
Terraform in this repository provisions AWS infrastructure (including EKS) and deploys Jenkins to the cluster using the official Jenkins Helm chart.

##### JCasC
- Jenkins is configured using **Jenkins Configuration as Code (JCasC)** so controller configuration is declarative, versioned, and reproducible across environments.

##### Build Agents
- Jenkins build agents run as Kubernetes pods in the cluster, which supports scalable and isolated CI workloads.

##### Persistence
- Jenkins data is persisted so controller state survives pod restarts and redeployments.

For implementation details, see [Further Reading - Jenkins Configuration as Code (JCasC)](#jenkins-configuration-as-code-jcasc).

## Argo CD
Argo CD is installed in the EKS cluster to provide GitOps-based continuous delivery.

- This platform uses the **App of Apps** pattern, where a parent Argo CD application manages child applications for workload components.

- Repository responsibilities are separated: [**infra-aws**](https://github.com/dana951/infra-aws) provisions and bootstraps Argo CD, while [**argocd-apps**](https://github.com/dana951/argocd-apps) contains the GitOps application definitions managed by Argo CD.

For implementation details, see [Further Reading - Argo CD App of Apps](#argo-cd-app-of-apps).

## Further Reading
- [Jenkins Configuration as Code (JCasC)](#jenkins-configuration-as-code-jcasc)
- [Argo CD App of Apps](#argo-cd-app-of-apps)

### Jenkins Configuration as Code (JCasC)

In this repository, we explicitly install the JCasC plugin (`configuration-as-code`) in `accounts/devops/eks-tools/values/jenkins-values.yaml` under `controller.installPlugins`.

We also install the Jenkins Kubernetes plugin (`kubernetes`) from the same values file (`controller.installPlugins`) to run agents as pods in EKS.

How jcasc works during deployment:
- We define [Jenkins](#jenkins) configuration in Helm values (`controller.JCasC`).
- When Helm deploys Jenkins, it creates a JCasC ConfigMap named `jenkins-jenkins-jcasc-config` that contains YAML data (for example, `jcasc-default-config.yaml`).
- This ConfigMap is used by the Jenkins config-reload sidecar (`kiwigrid/k8s-sidecar`), which is enabled through `controller.sidecars.configAutoReload`.
- The `kiwigrid/k8s-sidecar` is a utility container used in Jenkins Kubernetes deployments to  
  automate configuration updates without requiring a manual restart of the Jenkins controller
- The sidecar monitors only ConfigMaps that have specific labels (e.g: `jenkins-jenkins-config: "true"`).
- The sidecar reads the ConfigMap data and writes it as YAML files into `/var/jenkins_home/casc_configs` (via shared volume accessible by the Jenkins container).
- The Jenkins container sets `CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs`.
- The Jenkins Configuration as Code plugin reads that path and applies the YAML on startup.
- If configuration changes later, the sidecar calls Jenkins reload endpoint (`/reload-configuration-as-code`) so JCasC is re-applied without a full controller restart.

Agent and persistence details:
- Jenkins agents are enabled as Kubernetes pods (`agent.enabled: true`) in namespace `jenkins-agents`.
- Agent pod placement is controlled with `agent.nodeSelector` and `agent.tolerations` to target the dedicated `jenkins-agents` node group.
- Jenkins relies on the cluster `aws-ebs-csi-driver` addon for dynamic EBS volume provisioning; the Helm chart uses PVC/StorageClass resources 
- Persistent storage is enabled with `ebs-csi` which is the StorageClass that uses the ebs.csi.aws.com provisioner (`persistence.enabled`, `persistence.storageClass`, `persistence.size`).


### Argo CD App of Apps
How it works during deployment:
- Terraform installs Argo CD via Helm into the `argocd` namespace.
- Terraform then applies `argocd_main_app` from the [**argocd-apps**](https://github.com/dana951/argocd-apps) repository.
- That parent application points to child Argo CD Applications (App of Apps pattern).
- Each child application manages the `podinfo` application for a specific environment (dev, qa, staging, prod).
- Argo CD continuously reconciles applications from Git to cluster state.

