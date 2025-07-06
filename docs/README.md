# Azure AKS Demo with Istio, ArgoCD, and Secure Nginx Microservice

## 🎯 Project Overview

This project demonstrates a production-ready AKS cluster with:

- **Private AKS Cluster** in private subnet
- **Private Azure Container Registry (ACR)**
- **Istio Service Mesh** with mTLS enabled
- **ArgoCD** for GitOps deployment
- **Nginx Microservice** with full security hardening
- **Monitoring Stack** (Prometheus, Grafana, Kiali, Jaeger)
- **Comprehensive Security** (Network Policies, RBAC, Pod Security)

## 🏗️ Architecture

```
Internet
    ↓
Load Balancer (Public IP)
    ↓
Istio Ingress Gateway
    ↓
Nginx Frontend (mTLS) ←→ Nginx Backend
    ↓
Private AKS Cluster
    ↓
Private ACR
```

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and logged in
- kubectl installed
- Helm installed
- Terraform installed
- SSH key pair (`~/.ssh/id_rsa`)

### 1. Deploy Infrastructure

```bash
cd /root/azure-aks-demo
./scripts/setup-cluster.sh
```

This will:
- Create AKS cluster in private subnet
- Set up private ACR
- Install Istio service mesh
- Install ArgoCD
- Install monitoring stack (Prometheus/Grafana)

### 2. Deploy Nginx Microservice

```bash
./scripts/deploy-nginx.sh
```

This will:
- Deploy Nginx frontend and backend with mTLS
- Apply security policies and network policies
- Configure Istio Gateway and VirtualService
- Set up ArgoCD application

### 3. Access Dashboards

```bash
./scripts/setup-access.sh
```

This will set up port forwards for:
- ArgoCD: https://localhost:8080
- Grafana: http://localhost:3000
- Kiali: http://localhost:20001
- Jaeger: http://localhost:16686

## 🔐 Security Features

### Istio Service Mesh Security
- **mTLS STRICT mode** for all pod-to-pod communication
- **Authorization Policies** for fine-grained access control
- **Gateway TLS termination** with custom certificates

### Kubernetes Security
- **Network Policies** for micro-segmentation
- **Pod Security Context** (non-root, read-only filesystem)
- **RBAC** with least privilege access
- **Resource Quotas** and limits
- **Pod Disruption Budgets**

### Container Security
- **Non-root containers** (UID 101)
- **Read-only root filesystem**
- **Dropped capabilities** (ALL)
- **Security scanning** ready
- **Resource limits** enforced

## 📊 Monitoring and Observability

### Grafana Dashboards
- Kubernetes cluster metrics
- Istio service mesh metrics
- Application performance metrics
- Resource utilization

### Kiali Service Mesh
- Service topology visualization
- Traffic flow analysis
- Security policy validation
- Configuration validation

### Jaeger Distributed Tracing
- Request tracing across services
- Performance bottleneck identification
- Error tracking and analysis

## 🔧 Management

### ArgoCD GitOps
- Automated deployment from Git
- Configuration drift detection
- Rollback capabilities
- Multi-environment support

### Cluster Access
```bash
# Get cluster credentials
az aks get-credentials --resource-group rg-aks-demo --name aks-demo-cluster

# Access via bastion host
ssh azureuser@<bastion-ip>
```

## 🧪 Testing and Validation

### Verify mTLS
```bash
# Check mTLS configuration
istioctl proxy-config cluster deployment/nginx-frontend.nginx-demo

# Test service communication
kubectl exec -n nginx-demo deployment/nginx-frontend -- curl -s nginx-backend
```

### Security Validation
```bash
# Check network policies
kubectl get networkpolicies -n nginx-demo

# Verify pod security context
kubectl get pods -n nginx-demo -o jsonpath='{.items[*].spec.securityContext}'

# Check RBAC
kubectl auth can-i --list --as=system:serviceaccount:nginx-demo:nginx-sa -n nginx-demo
```

### Performance Testing
```bash
# Load test the application
kubectl run -i --tty load-test --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod:
# while true; do wget -q -O- http://nginx-frontend.nginx-demo/; sleep 1; done
```

## 📁 Project Structure

```
azure-aks-demo/
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Main Terraform configuration
│   └── providers.tf        # Provider configurations
├── manifests/              # Kubernetes manifests
│   ├── nginx-deployment.yaml      # Nginx application
│   ├── security-policies.yaml    # Security configurations
│   └── argocd-application.yaml   # ArgoCD app definition
├── scripts/                # Automation scripts
│   ├── setup-cluster.sh    # Cluster setup
│   ├── deploy-nginx.sh     # Application deployment
│   └── setup-access.sh     # Dashboard access
└── docs/                   # Documentation
    └── README.md           # This file
```

## 🔍 Troubleshooting

### Common Issues

1. **Cluster Access Issues**
   ```bash
   # Re-get credentials
   az aks get-credentials --resource-group rg-aks-demo --name aks-demo-cluster --overwrite-existing
   ```

2. **Port Forward Issues**
   ```bash
   # Stop all port forwards
   ./stop-access.sh
   # Restart
   ./access-dashboards.sh
   ```

3. **ArgoCD Password Issues**
   ```bash
   # Get ArgoCD admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

### Logs and Debugging
```bash
# Check pod logs
kubectl logs -n nginx-demo deployment/nginx-frontend

# Check Istio proxy logs
kubectl logs -n nginx-demo deployment/nginx-frontend -c istio-proxy

# Check ArgoCD application status
kubectl get applications -n argocd

# Check Istio configuration
istioctl analyze -n nginx-demo
```

## 🧹 Cleanup

```bash
# Delete the resource group (removes everything)
az group delete --name rg-aks-demo --yes --no-wait

# Or use Terraform
cd terraform
terraform destroy
```

## 📚 Additional Resources

- [Istio Documentation](https://istio.io/latest/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**🎉 Happy Kubernetes-ing!** 🚀
