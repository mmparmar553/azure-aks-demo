#!/bin/bash

echo "🌐 Setting up SSH tunnels to access AKS dashboards via bastion host"

BASTION_IP="40.71.212.7"
BASTION_USER="azureuser"

echo "📋 Dashboard Access Setup"
echo "========================"
echo "Bastion Host: $BASTION_IP"
echo "SSH User: $BASTION_USER"
echo ""

echo "🔧 Step 1: Copy files to bastion host"
echo "scp /root/azure-aks-demo/scripts/setup-from-bastion.sh $BASTION_USER@$BASTION_IP:~/"
echo "scp -r /root/azure-aks-demo/manifests $BASTION_USER@$BASTION_IP:~/"
echo ""

echo "🚀 Step 2: SSH to bastion and run setup"
echo "ssh $BASTION_USER@$BASTION_IP"
echo "# Then on bastion host:"
echo "chmod +x setup-from-bastion.sh"
echo "./setup-from-bastion.sh"
echo ""

echo "🌐 Step 3: Set up port forwards on bastion host"
echo "# Run these commands on bastion host (in separate terminals):"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0"
echo "kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 --address 0.0.0.0"
echo "kubectl port-forward svc/kiali -n istio-system 20001:20001 --address 0.0.0.0"
echo "kubectl port-forward svc/tracing -n istio-system 16686:80 --address 0.0.0.0"
echo ""

echo "🔗 Step 4: Create SSH tunnels from your local machine"
echo "# Run these commands from your local machine (in separate terminals):"
echo "ssh -L 8080:localhost:8080 $BASTION_USER@$BASTION_IP  # ArgoCD"
echo "ssh -L 3000:localhost:3000 $BASTION_USER@$BASTION_IP  # Grafana"
echo "ssh -L 20001:localhost:20001 $BASTION_USER@$BASTION_IP  # Kiali"
echo "ssh -L 16686:localhost:16686 $BASTION_USER@$BASTION_IP  # Jaeger"
echo ""

echo "🌐 Step 5: Access dashboards in your browser"
echo "ArgoCD:  https://localhost:8080"
echo "Grafana: http://localhost:3000"
echo "Kiali:   http://localhost:20001"
echo "Jaeger:  http://localhost:16686"
echo ""

echo "🔑 Credentials:"
echo "ArgoCD:  admin / (get password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "Grafana: admin / admin123"
echo "Kiali:   No authentication required"
echo "Jaeger:  No authentication required"
echo ""

echo "🎯 Quick Start Commands:"
echo "========================"

# Create a comprehensive script for easy access
cat > /root/azure-aks-demo/quick-start.sh << EOF
#!/bin/bash

echo "🚀 AKS Demo Quick Start"
echo "======================="

echo "1. Copy files to bastion:"
scp /root/azure-aks-demo/scripts/setup-from-bastion.sh azureuser@40.71.212.7:~/
scp -r /root/azure-aks-demo/manifests azureuser@40.71.212.7:~/

echo "2. SSH to bastion and run setup:"
echo "   ssh azureuser@40.71.212.7"
echo "   ./setup-from-bastion.sh"

echo "3. Deploy Nginx microservice:"
echo "   kubectl apply -f manifests/security-policies.yaml"
echo "   kubectl apply -f manifests/nginx-deployment.yaml"

echo "4. Access dashboards via SSH tunnels"
echo "   See access-dashboards-via-bastion.sh for details"

echo ""
echo "✅ Infrastructure is ready!"
echo "📍 Bastion IP: 40.71.212.7"
echo "🔐 SSH Key: ~/.ssh/id_rsa"
EOF

chmod +x /root/azure-aks-demo/quick-start.sh

echo "✅ Quick start script created: /root/azure-aks-demo/quick-start.sh"
echo ""
echo "🎉 Your AKS cluster infrastructure is ready!"
echo "📋 Next: Run ./quick-start.sh to begin the setup process"
