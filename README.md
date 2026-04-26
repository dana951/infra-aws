# infra-aws
WIP - Infrastructure provisioning for a production-grade EKS cluster hosting a GitOps-based CI/CD platform (Jenkins/argocd)

This repository is part of the [**eks-gitops-platform**](https://github.com/dana951/eks-gitops-platform) project - GitOps CI/CD workflow on AWS EKS. 

## Jenkins
Terraform in this repository provisions AWS infrastructure (including EKS) and deploys Jenkins to the cluster using the official Jenkins Helm chart.

Jenkins is configured using **Jenkins Configuration as Code (JCasC)** so controller configuration is declarative, versioned, and reproducible across environments.

For implementation details, see [Further Reading - Jenkins Configuration as Code (JCasC)](#jenkins-configuration-as-code-jcasc).

## Further Reading
### Jenkins Configuration as Code (JCasC)

In this repository, we explicitly install the JCasC plugin (`configuration-as-code`) in `accounts/devops/eks-tools/values/jenkins-values.yaml` under `controller.installPlugins`.

How it works during deployment:
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
