#!/bin/bash

set -e

echo "🚀 Starting AKS Demo Cluster Setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Please install Azure CLI."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    print_error "Helm not found. Please install Helm."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install Terraform."
    exit 1
fi

print_success "All prerequisites found"

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    print_status "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    print_success "SSH key generated"
fi

# Change to terraform directory
cd /root/azure-aks-demo/terraform

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Plan Terraform deployment
print_status "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply Terraform deployment
print_status "Applying Terraform deployment..."
terraform apply tfplan

# Get outputs
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
BASTION_IP=$(terraform output -raw bastion_public_ip)
LB_IP=$(terraform output -raw load_balancer_ip)

print_success "Infrastructure deployed successfully"
print_status "Resource Group: $RESOURCE_GROUP"
print_status "AKS Cluster: $AKS_CLUSTER_NAME"
print_status "ACR Server: $ACR_LOGIN_SERVER"
print_status "Bastion IP: $BASTION_IP"
print_status "Load Balancer IP: $LB_IP"

# Get AKS credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

# Wait for cluster to be ready
print_status "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

print_success "AKS cluster is ready"

# Install Istio
print_status "Installing Istio..."
cd /root/azure-aks-demo

# Download Istio
if [ ! -d "istio-1.20.0" ]; then
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh -
fi

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

# Install monitoring stack (Prometheus, Grafana)
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

print_success "🎉 AKS Demo Cluster Setup Complete!"
print_status "Next steps:"
print_status "1. Run ./deploy-nginx.sh to deploy the Nginx microservice"
print_status "2. Run ./setup-access.sh to configure GUI access"
print_status "3. Check the docs/ folder for access instructions"

# Save important information
cat > /root/azure-aks-demo/cluster-info.txt << EOF
AKS Demo Cluster Information
============================

Resource Group: $RESOURCE_GROUP
AKS Cluster: $AKS_CLUSTER_NAME
ACR Server: $ACR_LOGIN_SERVER
Bastion IP: $BASTION_IP
Load Balancer IP: $LB_IP

Access Information:
- ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443
- Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
- Istio Kiali: kubectl port-forward svc/kiali -n istio-system 20001:20001
- Istio Jaeger: kubectl port-forward svc/tracing -n istio-system 16686:80

Default Credentials:
- ArgoCD: admin / (get password with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
- Grafana: admin / admin123
EOF

print_success "Cluster information saved to cluster-info.txt"
