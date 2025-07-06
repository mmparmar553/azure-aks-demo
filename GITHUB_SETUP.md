# GitHub Repository Setup Instructions

## 🚀 Step 1: Create GitHub Repository

### Option A: Using GitHub CLI (if installed)
```bash
# Install GitHub CLI if not available
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# Login to GitHub
gh auth login

# Create repository
gh repo create azure-aks-demo --public --description "Azure AKS Demo with GitOps deployment using ArgoCD, Istio service mesh, and comprehensive monitoring stack"

# Push code
git remote add origin https://github.com/YOUR_USERNAME/azure-aks-demo.git
git branch -M main
git push -u origin main
```

### Option B: Manual GitHub Creation
1. Go to https://github.com/new
2. Repository name: `azure-aks-demo`
3. Description: `Azure AKS Demo with GitOps deployment using ArgoCD, Istio service mesh, and comprehensive monitoring stack`
4. Set to Public
5. Click "Create repository"

Then run these commands:
```bash
cd /root/azure-aks-demo
git remote add origin https://github.com/YOUR_USERNAME/azure-aks-demo.git
git branch -M main
git push -u origin main
```

## 🔄 Step 2: Configure ArgoCD Application

After creating the GitHub repository, update the ArgoCD application configuration:

```bash
# Update the repository URL in the ArgoCD application
sed -i 's/YOUR_USERNAME/your-actual-github-username/g' /root/azure-aks-demo/gitops/argocd/application.yaml

# Commit the change
git add gitops/argocd/application.yaml
git commit -m "Update ArgoCD application with correct GitHub repository URL"
git push
```

## 🎯 Step 3: Deploy ArgoCD Application

Connect to your AKS cluster and deploy the ArgoCD application:

```bash
# Connect to bastion host
ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7

# Apply the ArgoCD application
kubectl apply -f /path/to/azure-aks-demo/gitops/argocd/application.yaml

# Check application status
kubectl get applications -n argocd
kubectl describe application nginx-gitops-app -n argocd
```

## 📊 Step 4: Monitor Deployment

1. **ArgoCD UI**: https://40.121.190.173
   - Username: admin
   - Password: Kyku9ZJ8O3eymmpG

2. **Check Application Sync Status**:
   ```bash
   kubectl get applications -n argocd -w
   ```

3. **View Application Details**:
   ```bash
   kubectl describe application nginx-gitops-app -n argocd
   ```

## 🔄 Step 5: Test GitOps Workflow

1. **Make a change to the application**:
   ```bash
   # Edit the ConfigMap to change the webpage content
   vim gitops/k8s-manifests/configmap.yaml
   
   # Commit and push changes
   git add .
   git commit -m "Update nginx webpage content"
   git push
   ```

2. **Watch ArgoCD automatically sync the changes**:
   - Check ArgoCD UI for sync status
   - Verify changes are applied to the cluster
   - Visit http://4.236.207.28 to see updated content

## 🎉 Success Indicators

✅ GitHub repository created and code pushed
✅ ArgoCD application deployed and syncing
✅ Automatic deployment on git push working
✅ All services accessible via external IPs
✅ GitOps workflow fully operational

## 🔧 Troubleshooting

### ArgoCD Application Not Syncing
```bash
# Check application status
kubectl get application nginx-gitops-app -n argocd -o yaml

# Force sync if needed
kubectl patch application nginx-gitops-app -n argocd --type merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{"force":true}}}}}'
```

### Repository Access Issues
- Ensure repository is public or ArgoCD has proper credentials
- Check repository URL is correct in application.yaml
- Verify network connectivity from cluster to GitHub

### Deployment Issues
```bash
# Check pod status
kubectl get pods -n nginx-app

# Check events
kubectl get events -n nginx-app --sort-by='.lastTimestamp'

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```
