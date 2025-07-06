#!/bin/bash

set -e

echo "🔧 Setting up GUI Access for ArgoCD, Istio, and Grafana"

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

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 1
    else
        return 0
    fi
}

# Function to start port forward in background
start_port_forward() {
    local service=$1
    local namespace=$2
    local local_port=$3
    local remote_port=$4
    local name=$5
    
    if check_port $local_port; then
        print_status "Starting port-forward for $name on port $local_port..."
        kubectl port-forward svc/$service -n $namespace $local_port:$remote_port > /dev/null 2>&1 &
        local pid=$!
        echo $pid > /tmp/${name}_port_forward.pid
        sleep 2
        if kill -0 $pid 2>/dev/null; then
            print_success "$name port-forward started (PID: $pid)"
            return 0
        else
            print_error "Failed to start $name port-forward"
            return 1
        fi
    else
        print_warning "Port $local_port is already in use for $name"
        return 1
    fi
}

# Stop any existing port forwards
print_status "Stopping any existing port forwards..."
pkill -f "kubectl port-forward" || true
sleep 2

# Start ArgoCD port forward
start_port_forward "argocd-server" "argocd" "8080" "443" "argocd"

# Start Grafana port forward
start_port_forward "prometheus-grafana" "monitoring" "3000" "80" "grafana"

# Start Kiali port forward
start_port_forward "kiali" "istio-system" "20001" "20001" "kiali"

# Start Jaeger port forward
start_port_forward "tracing" "istio-system" "16686" "80" "jaeger"

# Get ArgoCD admin password
print_status "Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Password not available yet")

# Create access script
cat > /root/azure-aks-demo/access-dashboards.sh << 'EOF'
#!/bin/bash

echo "🌐 Starting Dashboard Access..."

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 1
    else
        return 0
    fi
}

# Function to start port forward in background
start_port_forward() {
    local service=$1
    local namespace=$2
    local local_port=$3
    local remote_port=$4
    local name=$5
    
    if check_port $local_port; then
        echo "Starting port-forward for $name on port $local_port..."
        kubectl port-forward svc/$service -n $namespace $local_port:$remote_port > /dev/null 2>&1 &
        local pid=$!
        echo $pid > /tmp/${name}_port_forward.pid
        sleep 2
        if kill -0 $pid 2>/dev/null; then
            echo "✅ $name port-forward started (PID: $pid)"
            return 0
        else
            echo "❌ Failed to start $name port-forward"
            return 1
        fi
    else
        echo "⚠️  Port $local_port is already in use for $name"
        return 1
    fi
}

# Stop existing port forwards
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# Start all port forwards
start_port_forward "argocd-server" "argocd" "8080" "443" "argocd"
start_port_forward "prometheus-grafana" "monitoring" "3000" "80" "grafana"
start_port_forward "kiali" "istio-system" "20001" "20001" "kiali"
start_port_forward "tracing" "istio-system" "16686" "80" "jaeger"

echo ""
echo "🎉 All dashboards are now accessible!"
echo ""
echo "📊 Dashboard URLs:"
echo "=================="
echo "🔐 ArgoCD:    https://localhost:8080"
echo "📈 Grafana:   http://localhost:3000"
echo "🕸️  Kiali:    http://localhost:20001"
echo "🔍 Jaeger:    http://localhost:16686"
echo ""
echo "🔑 Credentials:"
echo "==============="
echo "ArgoCD:  admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Password not available")"
echo "Grafana: admin / admin123"
echo "Kiali:   No authentication required"
echo "Jaeger:  No authentication required"
echo ""
echo "⚠️  Note: Keep this terminal open to maintain port forwards"
echo "To stop all port forwards, press Ctrl+C or run: pkill -f 'kubectl port-forward'"
echo ""

# Keep script running
trap 'echo "Stopping port forwards..."; pkill -f "kubectl port-forward"; exit 0' INT TERM
while true; do
    sleep 10
done
EOF

chmod +x /root/azure-aks-demo/access-dashboards.sh

# Create stop script
cat > /root/azure-aks-demo/stop-access.sh << 'EOF'
#!/bin/bash

echo "🛑 Stopping all dashboard port forwards..."

# Kill all kubectl port-forward processes
pkill -f "kubectl port-forward" 2>/dev/null || true

# Remove PID files
rm -f /tmp/*_port_forward.pid

echo "✅ All port forwards stopped"
EOF

chmod +x /root/azure-aks-demo/stop-access.sh

print_success "🎉 GUI Access Setup Complete!"

cat << EOF

📊 Dashboard Access Information:
===============================

🔐 ArgoCD:    https://localhost:8080
📈 Grafana:   http://localhost:3000  
🕸️  Kiali:    http://localhost:20001
🔍 Jaeger:    http://localhost:16686

🔑 Credentials:
===============
ArgoCD:  admin / $ARGOCD_PASSWORD
Grafana: admin / admin123
Kiali:   No authentication required
Jaeger:  No authentication required

🚀 Quick Access Commands:
========================
./access-dashboards.sh  - Start all dashboard port forwards
./stop-access.sh        - Stop all port forwards

⚠️  Important Notes:
===================
- Port forwards are running in background
- Keep terminal open to maintain access
- Use Ctrl+C to stop port forwards
- ArgoCD uses HTTPS (accept self-signed certificate)

🔧 Manual Port Forward Commands:
===============================
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
kubectl port-forward svc/kiali -n istio-system 20001:20001
kubectl port-forward svc/tracing -n istio-system 16686:80

EOF

# Save access information
cat > /root/azure-aks-demo/access-info.txt << EOF
Dashboard Access Information
===========================

Generated: $(date)

URLs:
- ArgoCD:    https://localhost:8080
- Grafana:   http://localhost:3000
- Kiali:     http://localhost:20001
- Jaeger:    http://localhost:16686

Credentials:
- ArgoCD:  admin / $ARGOCD_PASSWORD
- Grafana: admin / admin123
- Kiali:   No authentication required
- Jaeger:  No authentication required

Scripts:
- ./access-dashboards.sh - Start all dashboards
- ./stop-access.sh - Stop all port forwards

Manual Commands:
- kubectl port-forward svc/argocd-server -n argocd 8080:443
- kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
- kubectl port-forward svc/kiali -n istio-system 20001:20001
- kubectl port-forward svc/tracing -n istio-system 16686:80
EOF

print_success "Access information saved to access-info.txt"
print_status "Port forwards are running in background. Use ./stop-access.sh to stop them."
