# 🚀 Create GitHub Repository - Step by Step

## 📋 Quick Setup Instructions

### Step 1: Create GitHub Repository
1. **Go to**: https://github.com/new
2. **Repository name**: `azure-aks-demo`
3. **Description**: `Azure AKS Demo with GitOps deployment using ArgoCD, Istio service mesh, and comprehensive monitoring stack`
4. **Visibility**: ✅ Public
5. **Initialize**: ❌ Do NOT initialize with README, .gitignore, or license (we already have these)
6. **Click**: "Create repository"

### Step 2: Push Code to GitHub
After creating the repository, GitHub will show you commands. Use these:

```bash
cd /root/azure-aks-demo

# Add your GitHub username to the remote URL
git remote set-url origin https://github.com/YOUR_GITHUB_USERNAME/azure-aks-demo.git

# Push the code
git push -u origin main
```

### Step 3: Update ArgoCD Application
```bash
# Replace YOUR_GITHUB_USERNAME with your actual username
sed -i 's|https://github.com//azure-aks-demo.git|https://github.com/YOUR_GITHUB_USERNAME/azure-aks-demo.git|g' gitops/argocd/application.yaml

# Commit and push the update
git add gitops/argocd/application.yaml
git commit -m "Fix ArgoCD application repository URL"
git push
```

### Step 4: Update ArgoCD Application in Cluster
```bash
# Connect to bastion and update the application
ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl apply -f ~/argocd-application.yaml"

# Or copy the updated file and apply it
scp -i ~/.ssh/id_rsa gitops/argocd/application.yaml azureuser@40.71.212.7:~/argocd-application-updated.yaml
ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl apply -f ~/argocd-application-updated.yaml"
```

## 🎯 Alternative: Using GitHub CLI

If you have GitHub CLI installed:

```bash
# Install GitHub CLI (if not installed)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# Login to GitHub
gh auth login

# Create repository and push
gh repo create azure-aks-demo --public --description "Azure AKS Demo with GitOps deployment using ArgoCD, Istio service mesh, and comprehensive monitoring stack"
git push -u origin main
```

## ✅ Verification Steps

After setting up GitHub:

1. **Check ArgoCD Application**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl get applications -n argocd"
   ```

2. **Check Application Details**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl describe application nginx-gitops-app -n argocd"
   ```

3. **Access ArgoCD UI**: https://40.121.190.173
   - Username: `admin`
   - Password: `Kyku9ZJ8O3eymmpG`

## 🧪 Test GitOps Workflow

Once GitHub is set up, test the GitOps workflow:

1. **Make a change**:
   ```bash
   # Edit the webpage content
   vim gitops/k8s-manifests/configmap.yaml
   # Change the version number or add some text
   ```

2. **Commit and push**:
   ```bash
   git add .
   git commit -m "Test GitOps: Update webpage content"
   git push
   ```

3. **Watch ArgoCD sync**:
   - Check ArgoCD UI for automatic sync
   - Visit http://4.236.207.28 to see changes

## 🎉 Success Indicators

✅ GitHub repository created and accessible
✅ Code pushed to GitHub successfully  
✅ ArgoCD application pointing to correct repository
✅ ArgoCD showing sync status (may be "OutOfSync" initially)
✅ GitOps workflow operational

## 🔧 Troubleshooting

### Repository Access Issues
- Ensure repository is **public**
- Check repository URL is correct
- Verify network connectivity from cluster

### ArgoCD Sync Issues
```bash
# Force sync if needed
ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl patch application nginx-gitops-app -n argocd --type merge -p '{\"spec\":{\"syncPolicy\":{\"automated\":{\"prune\":true,\"selfHeal\":true}}}}'"
```

### Check Application Status
```bash
ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl get application nginx-gitops-app -n argocd -o yaml"
```
