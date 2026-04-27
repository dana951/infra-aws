# infra-aws
WIP - Infrastructure provisioning for a production-grade EKS cluster hosting a GitOps-based CI/CD platform (Jenkins/argocd)

This repository is part of the [**eks-gitops-platform**](https://github.com/dana951/eks-gitops-platform) project - GitOps CI/CD workflow on AWS EKS. 

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
- Persistent storage is enabled with `gp3` which is the StorageClass with the  that uses the ebs.csi.aws.com provisioner (`persistence.enabled`, `persistence.storageClass`, `persistence.size`).


### Argo CD App of Apps
How it works during deployment:
- Terraform installs Argo CD via Helm into the `argocd` namespace.
- Terraform then applies `argocd_main_app` from the [**argocd-apps**](https://github.com/dana951/argocd-apps) repository.
- That parent application points to child Argo CD Applications (App of Apps pattern).
- Each child application manages the `podinfo` application for a specific environment (dev, qa, staging, prod).
- Argo CD continuously reconciles applications from Git to cluster state.

