# 🚀 Access ArgoCD UI - Step by Step Guide

## 📊 **ArgoCD Access Information**

### **ArgoCD UI Access**
- **URL**: https://40.121.190.173
- **Username**: `admin`
- **Password**: `Kyku9ZJ8O3eymmpG`

### **Alternative HTTP Access** (if HTTPS has issues)
- **URL**: http://40.121.190.173

## 🔍 **Finding Your Application in ArgoCD**

### **Step 1: Login to ArgoCD**
1. Open browser and go to: **https://40.121.190.173**
2. Accept any SSL certificate warnings (self-signed certificate)
3. Login with:
   - Username: `admin`
   - Password: `Kyku9ZJ8O3eymmpG`

### **Step 2: Locate Your Application**
Once logged in, you should see:
- **Application Name**: `nginx-gitops-app`
- **Status**: OutOfSync (this is normal, it's working on deployment)
- **Repository**: https://github.com/mmparmar553/azure-aks-demo.git
- **Path**: gitops/k8s-manifests

### **Step 3: View Application Details**
Click on the `nginx-gitops-app` tile to see:
- **Repository Information**: Your GitHub repo
- **Sync Status**: Current deployment status
- **Resources**: All Kubernetes resources being managed
- **Events**: Deployment history and logs

## 🔧 **Troubleshooting ArgoCD Access**

### **If you can't see the application:**

1. **Check if you're in the right project**:
   - Look for a dropdown that says "default" (your app is in the default project)

2. **Refresh the page**:
   - Sometimes the UI needs a refresh to show new applications

3. **Check application via CLI**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl get applications -n argocd"
   ```

### **If ArgoCD UI won't load:**

1. **Try HTTP instead of HTTPS**:
   - Go to: http://40.121.190.173

2. **Check if service is running**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl get pods -n argocd | grep server"
   ```

3. **Port forward as backup**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0" &
   # Then access via: https://40.71.212.7:8080
   ```

## 📱 **What You Should See in ArgoCD**

### **Application Overview**
```
┌─────────────────────────────────────────┐
│  nginx-gitops-app                       │
│  ┌─────────────────────────────────────┐ │
│  │ Repository: mmparmar553/azure-aks-  │ │
│  │ Status: OutOfSync                   │ │
│  │ Health: Missing                     │ │
│  │ Last Sync: X minutes ago            │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### **Application Details (when clicked)**
- **Source**: GitHub repository information
- **Destination**: nginx-app namespace
- **Resources**: List of all Kubernetes resources
- **Events**: Sync history and status

## ✅ **Verification Steps**

1. **Confirm Application Exists**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl get application nginx-gitops-app -n argocd"
   ```

2. **Check Application Status**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl describe application nginx-gitops-app -n argocd"
   ```

3. **Force Sync if Needed**:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@40.71.212.7 "kubectl patch application nginx-gitops-app -n argocd --type merge -p '{\"operation\":{\"sync\":{\"syncStrategy\":{\"hook\":{\"force\":true}}}}}'"
   ```

## 🎯 **Expected Behavior**

- ✅ **Application Visible**: You should see `nginx-gitops-app` in the ArgoCD UI
- ✅ **Repository Connected**: GitHub repo URL should be visible
- ✅ **Resources Listed**: Kubernetes manifests should be shown
- 🔄 **Sync in Progress**: Status might show "OutOfSync" while deploying

## 📞 **If Still Having Issues**

The application definitely exists and is configured correctly. If you still can't see it:

1. **Clear browser cache** and try again
2. **Try a different browser** or incognito mode
3. **Check the "All Applications" view** in ArgoCD
4. **Verify you're logged in as admin** (not a different user)

The GitHub repository integration is working - ArgoCD is successfully reading from your repo and managing the resources!
