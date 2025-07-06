# Azure AKS Demo - GitOps Repository

This repository contains Kubernetes manifests for the Azure AKS demo application with GitOps deployment using ArgoCD.

## 🏗️ Architecture

- **Infrastructure**: Azure AKS with private cluster
- **Application**: Nginx web server with security hardening
- **Service Mesh**: Istio with mTLS encryption
- **GitOps**: ArgoCD for automated deployments
- **Monitoring**: Prometheus, Grafana, Kiali, Jaeger

## 📁 Repository Structure

```
azure-aks-demo/
├── terraform/              # Infrastructure as Code
├── gitops/                 # GitOps configurations
│   ├── k8s-manifests/     # Kubernetes YAML manifests
│   ├── argocd/            # ArgoCD application definitions
│   └── docs/              # Documentation
└── README.md
```

## 🚀 Current Deployment Status

Based on our conversation summary, the following services are already deployed:

| Service | External IP | Status | Access |
|---------|-------------|--------|--------|
| Nginx | 4.236.207.28 | ✅ Running | http://4.236.207.28 |
| Grafana | 74.179.240.75 | ✅ Running | http://74.179.240.75 |
| ArgoCD | 40.121.190.173 | ✅ Running | https://40.121.190.173 |
| Jaeger | 20.242.224.198 | ✅ Running | http://20.242.224.198 |
| Prometheus | 40.71.212.7:9090 | ✅ Running | http://40.71.212.7:9090 |
| Kiali | 40.71.212.7:20001 | ✅ Running | http://40.71.212.7:20001 |

## 🔄 GitOps Workflow

1. **Code Changes**: Push changes to this repository
2. **ArgoCD Detection**: ArgoCD monitors this repo for changes
3. **Automatic Sync**: Changes are automatically applied to the cluster
4. **Monitoring**: Track deployment status in ArgoCD UI

## 🔐 Credentials

- **ArgoCD**: admin / Kyku9ZJ8O3eymmpG
- **Grafana**: admin / admin123

## 📊 Monitoring & Observability

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboards and visualization
- **Kiali**: Service mesh observability
- **Jaeger**: Distributed tracing
- **Istio**: Service mesh with mTLS

## 🛡️ Security Features

- Private AKS cluster with bastion host access
- Istio service mesh with mTLS encryption
- Network Security Groups (NSGs) with restrictive rules
- Kubernetes Network Policies
- RBAC with least privilege access
- Pod Security Contexts (non-root, read-only filesystem)
- Resource quotas and limits

## 🔧 Infrastructure Components

- **AKS Cluster**: Private cluster with 3 nodes
- **Azure Container Registry**: Private registry (acraksdemoprivatetwx8vb4d.azurecr.io)
- **Virtual Network**: 10.0.0.0/16 with private subnets
- **Bastion Host**: Secure access to private resources
- **Load Balancers**: External IP access for services

## 📝 Version History

- **v1.0.0**: Initial infrastructure deployment
- **v1.1.0**: Added Istio service mesh
- **v1.2.0**: Implemented monitoring stack
- **v1.3.0**: GitOps integration with ArgoCD
