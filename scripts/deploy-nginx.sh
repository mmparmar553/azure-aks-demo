#!/bin/bash

set -e

echo "🚀 Deploying Nginx Microservice with mTLS and Security"

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

# Change to project directory
cd /root/azure-aks-demo

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot access Kubernetes cluster. Please run setup-cluster.sh first."
    exit 1
fi

print_status "Deploying security policies..."
kubectl apply -f manifests/security-policies.yaml

print_status "Deploying Nginx application..."
kubectl apply -f manifests/nginx-deployment.yaml

print_status "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/nginx-frontend -n nginx-demo
kubectl wait --for=condition=available --timeout=300s deployment/nginx-backend -n nginx-demo

print_success "Nginx deployments are ready"

# Generate TLS certificate for Istio Gateway
print_status "Generating TLS certificate..."
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=nginx-demo.local"

kubectl create secret tls nginx-tls-secret -n istio-system \
    --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl apply -f -

rm -f tls.key tls.crt

print_success "TLS certificate created"

# Deploy ArgoCD application
print_status "Deploying ArgoCD application..."
kubectl apply -f manifests/argocd-application.yaml

print_success "ArgoCD application deployed"

# Get service information
print_status "Getting service information..."

ISTIO_INGRESS_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$ISTIO_INGRESS_IP" ]; then
    ISTIO_INGRESS_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

print_success "🎉 Nginx Microservice Deployment Complete!"

cat << EOF

📋 Deployment Summary:
=====================

✅ Nginx Frontend: 2 replicas deployed
✅ Nginx Backend: 2 replicas deployed
✅ Istio mTLS: STRICT mode enabled
✅ Network Policies: Applied
✅ Security Policies: Applied
✅ ArgoCD Application: Deployed

🌐 Access Information:
=====================

Nginx Application: http://$ISTIO_INGRESS_IP (if LoadBalancer IP is available)

🔐 Security Features Enabled:
============================

✅ Istio Service Mesh with mTLS
✅ Network Policies for micro-segmentation
✅ Pod Security Context (non-root, read-only filesystem)
✅ Resource Limits and Quotas
✅ RBAC with least privilege
✅ Pod Disruption Budgets
✅ Authorization Policies

📊 Monitoring:
=============

Run the following commands to access monitoring dashboards:

# Grafana
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80

# Kiali (Istio Service Mesh)
kubectl port-forward svc/kiali -n istio-system 20001:20001

# Jaeger (Distributed Tracing)
kubectl port-forward svc/tracing -n istio-system 16686:80

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

🔍 Verification Commands:
========================

# Check pod security
kubectl get pods -n nginx-demo -o wide

# Verify mTLS
kubectl exec -n nginx-demo deployment/nginx-frontend -- curl -s nginx-backend

# Check Istio configuration
istioctl proxy-config cluster deployment/nginx-frontend.nginx-demo

# View network policies
kubectl get networkpolicies -n nginx-demo

EOF

# Save deployment info
cat > /root/azure-aks-demo/deployment-info.txt << EOF
Nginx Microservice Deployment Information
=========================================

Deployment Date: $(date)
Istio Ingress IP: $ISTIO_INGRESS_IP

Services:
- nginx-frontend: LoadBalancer service with Istio Gateway
- nginx-backend: ClusterIP service (internal only)

Security Features:
- Istio mTLS: STRICT mode
- Network Policies: Enabled
- Pod Security Context: Non-root, read-only filesystem
- RBAC: Least privilege access
- Resource Quotas: Applied

Monitoring Access:
- Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
- Kiali: kubectl port-forward svc/kiali -n istio-system 20001:20001
- Jaeger: kubectl port-forward svc/tracing -n istio-system 16686:80
- ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443

ArgoCD Admin Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
Grafana Password: admin123
EOF

print_success "Deployment information saved to deployment-info.txt"
