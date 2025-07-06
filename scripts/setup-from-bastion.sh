#!/bin/bash

set -e

echo "🚀 Setting up AKS Demo from Bastion Host"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install required tools on bastion
print_status "Installing required tools..."

# Update package list
sudo apt-get update -y

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

print_success "Tools installed successfully"

# Get AKS credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group rg-aks-demo --name aks-demo-cluster --overwrite-existing

# Wait for cluster to be ready
print_status "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

print_success "AKS cluster is ready"

# Download and install Istio
print_status "Installing Istio..."
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
export PATH=$PWD/istio-1.20.0/bin:$PATH

# Install Istio
istioctl install --set values.defaultRevision=default -y

# Enable Istio injection for default namespace
kubectl label namespace default istio-injection=enabled --overwrite

print_success "Istio installed successfully"

# Install ArgoCD
print_status "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
print_status "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

print_success "ArgoCD installed successfully"

# Install monitoring stack
print_status "Installing monitoring stack..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=LoadBalancer \
  --set prometheus.service.type=LoadBalancer

print_success "Monitoring stack installed successfully"

# Install Istio addons
print_status "Installing Istio addons..."
kubectl apply -f istio-1.20.0/samples/addons/

# Wait for addons to be ready
sleep 30

print_success "Istio addons installed successfully"

print_success "🎉 AKS Demo Cluster Setup Complete from Bastion!"

# Save important information
cat > cluster-info.txt << EOF
AKS Demo Cluster Information (From Bastion)
==========================================

Resource Group: rg-aks-demo
AKS Cluster: aks-demo-cluster
ACR Server: acraksdemoprivatetwx8vb4d.azurecr.io
Bastion IP: 40.71.212.7
Load Balancer IP: 172.190.10.83

Access Information:
- ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443
- Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
- Istio Kiali: kubectl port-forward svc/kiali -n istio-system 20001:20001
- Istio Jaeger: kubectl port-forward svc/tracing -n istio-system 16686:80

Default Credentials:
- ArgoCD: admin / (get password with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
- Grafana: admin / admin123

Next Steps:
1. Deploy Nginx microservice: kubectl apply -f /path/to/nginx-manifests
2. Set up port forwards for GUI access
3. Configure security policies
EOF

print_success "Setup completed! Check cluster-info.txt for details"
