#!/bin/bash

# Azure AKS Demo - GitOps Setup Script
# This script helps set up the GitOps workflow with ArgoCD

set -e

echo "🚀 Azure AKS Demo - GitOps Setup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f "gitops/argocd/application.yaml" ]]; then
    print_error "Please run this script from the azure-aks-demo directory"
    exit 1
fi

# Step 1: Check GitHub repository setup
echo ""
print_info "Step 1: GitHub Repository Setup"
echo "================================"

if git remote get-url origin >/dev/null 2>&1; then
    REPO_URL=$(git remote get-url origin)
    print_status "Git remote origin found: $REPO_URL"
    
    # Extract username from GitHub URL
    if [[ $REPO_URL =~ github\.com[:/]([^/]+)/([^/]+)\.git ]]; then
        GITHUB_USERNAME="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
        print_status "GitHub username: $GITHUB_USERNAME"
        print_status "Repository name: $REPO_NAME"
    else
        print_warning "Could not parse GitHub username from URL"
        read -p "Enter your GitHub username: " GITHUB_USERNAME
        REPO_NAME="azure-aks-demo"
    fi
else
    print_warning "No git remote origin found"
    echo ""
    echo "Please create a GitHub repository first:"
    echo "1. Go to https://github.com/new"
    echo "2. Repository name: azure-aks-demo"
    echo "3. Set to Public"
    echo "4. Click 'Create repository'"
    echo ""
    read -p "Enter your GitHub username: " GITHUB_USERNAME
    REPO_NAME="azure-aks-demo"
    
    # Add remote origin
    git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    git branch -M main
    
    print_info "Added git remote origin"
fi

# Step 2: Update ArgoCD application with correct repository URL
echo ""
print_info "Step 2: Update ArgoCD Application Configuration"
echo "=============================================="

GITHUB_REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Update the ArgoCD application YAML
sed -i "s|repoURL: https://github.com/YOUR_USERNAME/azure-aks-demo.git|repoURL: $GITHUB_REPO_URL|g" gitops/argocd/application.yaml
sed -i "s|repoURL: https://github.com/example/azure-aks-demo.git|repoURL: $GITHUB_REPO_URL|g" gitops/argocd/application.yaml

print_status "Updated ArgoCD application with repository URL: $GITHUB_REPO_URL"

# Step 3: Commit and push changes
echo ""
print_info "Step 3: Commit and Push Changes"
echo "==============================="

git add .
git commit -m "Configure GitOps: Update ArgoCD application with correct GitHub repository URL

- Updated repository URL in ArgoCD application configuration
- Ready for GitOps deployment workflow" || print_warning "No changes to commit"

if git push origin main 2>/dev/null; then
    print_status "Successfully pushed changes to GitHub"
else
    print_warning "Could not push to GitHub. Please push manually:"
    echo "git push origin main"
fi

# Step 4: Deploy ArgoCD Application
echo ""
print_info "Step 4: Deploy ArgoCD Application"
echo "================================="

print_info "Connecting to AKS cluster via bastion host..."

# Check if we can connect to the cluster
if ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl get nodes" >/dev/null 2>&1; then
    print_status "Successfully connected to AKS cluster"
    
    # Copy the ArgoCD application to bastion host
    scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa gitops/argocd/application.yaml azureuser@40.71.212.7:~/argocd-application.yaml
    
    # Apply the ArgoCD application
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl apply -f ~/argocd-application.yaml"
    
    print_status "ArgoCD application deployed successfully"
    
    # Check application status
    echo ""
    print_info "Checking ArgoCD application status..."
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl get applications -n argocd"
    
else
    print_error "Could not connect to AKS cluster"
    echo "Please manually deploy the ArgoCD application:"
    echo "1. Connect to bastion host: ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7"
    echo "2. Apply application: kubectl apply -f gitops/argocd/application.yaml"
fi

# Step 5: Display access information
echo ""
print_info "Step 5: Access Information"
echo "========================="

echo ""
echo "🎉 GitOps Setup Complete!"
echo ""
echo "📊 Service Access URLs:"
echo "├── 🌐 Nginx App:    http://4.236.207.28"
echo "├── 🚀 ArgoCD:       https://40.121.190.173 (admin / Kyku9ZJ8O3eymmpG)"
echo "├── 📊 Grafana:      http://74.179.240.75 (admin / admin123)"
echo "├── 🔍 Jaeger:       http://20.242.224.198"
echo "├── 📈 Prometheus:   http://40.71.212.7:9090"
echo "└── 🕸️ Kiali:        http://40.71.212.7:20001"
echo ""
echo "🔄 GitOps Workflow:"
echo "1. Make changes to files in gitops/k8s-manifests/"
echo "2. Commit and push to GitHub"
echo "3. ArgoCD automatically detects and syncs changes"
echo "4. Monitor deployment in ArgoCD UI"
echo ""
echo "🧪 Test the GitOps workflow:"
echo "1. Edit gitops/k8s-manifests/configmap.yaml"
echo "2. Change the webpage content"
echo "3. git add . && git commit -m 'Update webpage' && git push"
echo "4. Watch ArgoCD sync the changes automatically"
echo ""

print_status "Setup completed successfully! 🎉"
