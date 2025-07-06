#!/bin/bash

# Generate Load for Nginx Application - Dashboard Testing
# This script generates HTTP traffic to test Grafana dashboards

set -e

echo "🚀 Nginx Load Generator for Dashboard Testing"
echo "============================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Nginx service URL
NGINX_URL="http://4.236.207.28"

print_info "Testing Nginx application accessibility..."

# Test if Nginx is accessible
if curl -s --connect-timeout 5 "$NGINX_URL" > /dev/null; then
    print_status "Nginx application is accessible at $NGINX_URL"
else
    print_warning "Cannot reach Nginx application. Please check if it's running."
    exit 1
fi

print_info "Starting load generation..."
print_info "This will generate various HTTP requests to populate Grafana dashboards"
print_info "Press Ctrl+C to stop"

# Function to generate different types of requests
generate_load() {
    local duration=${1:-300}  # Default 5 minutes
    local concurrent=${2:-5}  # Default 5 concurrent requests
    
    print_info "Generating load for $duration seconds with $concurrent concurrent requests"
    
    # Array of endpoints to test
    endpoints=(
        "/"
        "/health"
        "/metrics"
        "/nonexistent"  # This will generate 404s
    )
    
    # Start background processes for load generation
    for i in $(seq 1 $concurrent); do
        {
            local end_time=$((SECONDS + duration))
            while [ $SECONDS -lt $end_time ]; do
                # Pick random endpoint
                endpoint=${endpoints[$RANDOM % ${#endpoints[@]}]}
                
                # Make request with random delay
                curl -s -w "Status: %{http_code}, Time: %{time_total}s\n" \
                     --connect-timeout 5 \
                     --max-time 10 \
                     "$NGINX_URL$endpoint" > /dev/null 2>&1 || true
                
                # Random delay between requests (0.1 to 2 seconds)
                sleep $(echo "scale=1; $RANDOM/32767*1.9+0.1" | bc -l 2>/dev/null || echo "0.5")
            done
        } &
    done
    
    # Monitor progress
    local start_time=$SECONDS
    while [ $((SECONDS - start_time)) -lt $duration ]; do
        local elapsed=$((SECONDS - start_time))
        local remaining=$((duration - elapsed))
        printf "\r${BLUE}ℹ️  Load generation in progress... %d/%d seconds (remaining: %d)${NC}" \
               $elapsed $duration $remaining
        sleep 1
    done
    
    print_status "\nLoad generation completed!"
    
    # Wait for background processes to finish
    wait
}

# Function to generate specific test patterns
generate_test_patterns() {
    print_info "Generating specific test patterns for dashboard validation..."
    
    # High frequency requests for 30 seconds
    print_info "Pattern 1: High frequency requests (30 seconds)"
    for i in {1..100}; do
        curl -s "$NGINX_URL" > /dev/null &
        curl -s "$NGINX_URL/health" > /dev/null &
        sleep 0.3
    done
    wait
    
    # Mixed success/error requests
    print_info "Pattern 2: Mixed success/error requests (30 seconds)"
    for i in {1..50}; do
        curl -s "$NGINX_URL" > /dev/null &
        curl -s "$NGINX_URL/nonexistent" > /dev/null &  # 404 errors
        curl -s "$NGINX_URL/health" > /dev/null &
        sleep 0.6
    done
    wait
    
    # Sustained load
    print_info "Pattern 3: Sustained moderate load (60 seconds)"
    generate_load 60 3
    
    print_status "Test patterns completed!"
}

# Main execution
case "${1:-default}" in
    "quick")
        print_info "Quick test mode (2 minutes)"
        generate_load 120 3
        ;;
    "test-patterns")
        generate_test_patterns
        ;;
    "sustained")
        print_info "Sustained load mode (10 minutes)"
        generate_load 600 5
        ;;
    "heavy")
        print_info "Heavy load mode (5 minutes, 10 concurrent)"
        generate_load 300 10
        ;;
    *)
        print_info "Default load mode (5 minutes)"
        generate_load 300 5
        ;;
esac

echo ""
print_status "Load generation finished!"
print_info "Check your Grafana dashboard at: http://74.179.240.75"
print_info "Dashboard: 'Nginx GitOps Application Dashboard'"
print_info "Login: admin / admin123"
