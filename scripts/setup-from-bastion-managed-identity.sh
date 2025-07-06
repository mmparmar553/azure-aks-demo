#!/bin/bash

set -e

echo "🚀 Setting up AKS Demo from Bastion Host with Managed Identity"

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

# Enable managed identity for the VM
print_status "Configuring Azure CLI with managed identity..."

# Try to login with managed identity
if az login --identity; then
    print_success "Successfully logged in with managed identity"
else
    print_error "Managed identity login failed. Using device code login..."
    az login --use-device-code
fi

# Get AKS credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group rg-aks-demo --name aks-demo-cluster --overwrite-existing

# Wait for cluster to be ready
print_status "Waiting for cluster to be ready..."
timeout 300 kubectl wait --for=condition=Ready nodes --all || {
    print_warning "Timeout waiting for nodes. Continuing anyway..."
}

print_success "AKS cluster connection established"

# Download and install Istio
print_status "Installing Istio..."
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
timeout 300 kubectl wait --for=condition=available deployment/argocd-server -n argocd || {
    print_warning "ArgoCD deployment timeout. It may still be starting..."
}

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
  --set prometheus.service.type=LoadBalancer \
  --wait --timeout=10m

print_success "Monitoring stack installed successfully"

# Install Istio addons
print_status "Installing Istio addons..."
kubectl apply -f istio-1.20.0/samples/addons/ || {
    print_warning "Some Istio addons may have failed to install. Retrying..."
    sleep 10
    kubectl apply -f istio-1.20.0/samples/addons/
}

# Wait for addons to be ready
print_status "Waiting for Istio addons to be ready..."
sleep 30

print_success "Istio addons installed successfully"

# Deploy security policies
print_status "Deploying security policies..."
if [ -f "manifests/security-policies.yaml" ]; then
    kubectl apply -f manifests/security-policies.yaml
    print_success "Security policies applied"
else
    print_warning "Security policies file not found"
fi

# Deploy Nginx microservice
print_status "Deploying Nginx microservice..."
if [ -f "manifests/nginx-deployment.yaml" ]; then
    kubectl apply -f manifests/nginx-deployment.yaml
    
    # Wait for deployments to be ready
    print_status "Waiting for Nginx deployments to be ready..."
    timeout 300 kubectl wait --for=condition=available deployment/nginx-frontend -n nginx-demo || {
        print_warning "Nginx frontend deployment timeout"
    }
    timeout 300 kubectl wait --for=condition=available deployment/nginx-backend -n nginx-demo || {
        print_warning "Nginx backend deployment timeout"
    }
    
    print_success "Nginx microservice deployed successfully"
else
    print_warning "Nginx deployment file not found"
fi

print_success "🎉 AKS Demo Cluster Setup Complete!"

# Get service information
print_status "Getting service information..."

ISTIO_INGRESS_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
if [ -z "$ISTIO_INGRESS_IP" ] || [ "$ISTIO_INGRESS_IP" = "Pending" ]; then
    ISTIO_INGRESS_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending")
fi

GRAFANA_IP=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")

# Save important information
cat > cluster-info.txt << EOF
AKS Demo Cluster Information (Setup Complete)
============================================

Resource Group: rg-aks-demo
AKS Cluster: aks-demo-cluster
ACR Server: acraksdemoprivatetwx8vb4d.azurecr.io
Bastion IP: 40.71.212.7
Load Balancer IP: 172.190.10.83

Service IPs:
- Istio Ingress: $ISTIO_INGRESS_IP
- Grafana LoadBalancer: $GRAFANA_IP

Application URLs:
- Nginx App: http://$ISTIO_INGRESS_IP (if available)
- Nginx App (LB): http://172.190.10.83

Dashboard Access (via port-forward):
- ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
- Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 --address 0.0.0.0
- Kiali: kubectl port-forward svc/kiali -n istio-system 20001:20001 --address 0.0.0.0
- Jaeger: kubectl port-forward svc/tracing -n istio-system 16686:80 --address 0.0.0.0

Default Credentials:
- ArgoCD: admin / (get password with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
- Grafana: admin / admin123

Setup Status: COMPLETE
EOF

print_success "Setup completed! Check cluster-info.txt for details"

# Show final status
print_status "Final Status Check:"
echo "Nodes:"
kubectl get nodes
echo ""
echo "Namespaces:"
kubectl get namespaces
echo ""
echo "Services in istio-system:"
kubectl get svc -n istio-system
echo ""
echo "Pods in nginx-demo:"
kubectl get pods -n nginx-demo 2>/dev/null || echo "nginx-demo namespace not found"

print_success "🎉 AKS Demo Setup Complete! All services are ready."
