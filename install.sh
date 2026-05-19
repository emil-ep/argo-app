#!/bin/bash

# E-Commerce Application Installation Script
# This script automates the complete installation process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  E-Commerce Application Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${GREEN}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi
echo "  ✓ kubectl found"

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi
echo "  ✓ Kubernetes cluster accessible"

# Check if ArgoCD is installed
ARGOCD_INSTALLED=false
if kubectl get namespace argocd &> /dev/null; then
    ARGOCD_INSTALLED=true
    echo "  ✓ ArgoCD detected"
fi

echo ""

# Ask deployment method
if [ "$ARGOCD_INSTALLED" = true ]; then
    echo -e "${YELLOW}Deployment Method:${NC}"
    echo "  1) ArgoCD (GitOps - Recommended)"
    echo "  2) Direct kubectl apply"
    echo ""
    read -p "Choose deployment method (1 or 2) [1]: " DEPLOY_METHOD
    DEPLOY_METHOD=${DEPLOY_METHOD:-1}
else
    echo -e "${YELLOW}ArgoCD not detected. Using direct kubectl deployment.${NC}"
    DEPLOY_METHOD=2
fi

echo ""

# Step 1: Setup secrets
echo -e "${GREEN}Step 1: Configuring Secrets${NC}"
echo "----------------------------"
echo ""

if [ -f "gitops/overlays/dev/secrets.env" ] && [ -f "gitops/overlays/dev/frontend-secrets.env" ]; then
    echo -e "${YELLOW}Secret files already exist.${NC}"
    read -p "Do you want to reconfigure secrets? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/setup-secrets.sh
    else
        echo "Using existing secret files..."
    fi
else
    ./scripts/setup-secrets.sh
fi

echo ""

# Step 2: Create Kubernetes secrets and configmaps
echo -e "${GREEN}Step 2: Creating Kubernetes Secrets & ConfigMaps${NC}"
echo "------------------------------------------------"
echo ""

# Create namespace
echo "Creating namespace..."
kubectl create namespace ecommerce-dev --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Create backend secret
echo "Creating backend-secret..."
kubectl create secret generic backend-secret \
  --from-env-file=gitops/overlays/dev/secrets.env \
  -n ecommerce-dev \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

# Create frontend configmap
echo "Creating frontend-config..."
kubectl create configmap frontend-config \
  --from-env-file=gitops/overlays/dev/frontend-secrets.env \
  -n ecommerce-dev \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

echo -e "${GREEN}✓ Secrets and ConfigMaps created${NC}"
echo ""

# Step 3: Deploy application
echo -e "${GREEN}Step 3: Deploying Application${NC}"
echo "------------------------------"
echo ""

if [ "$DEPLOY_METHOD" = "1" ]; then
    # ArgoCD deployment
    echo "Deploying via ArgoCD..."
    
    # Apply ArgoCD application
    kubectl apply -f gitops/argocd/application.yaml
    
    echo ""
    echo -e "${GREEN}✓ ArgoCD Application created${NC}"
    echo ""
    echo "Waiting for ArgoCD to sync..."
    sleep 5
    
    # Trigger sync
    kubectl patch application ecommerce-dev -n argocd \
      --type merge \
      -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"master"}}}' 2>/dev/null || true
    
    echo ""
    echo -e "${YELLOW}Monitoring deployment (this may take 1-2 minutes)...${NC}"
    
    # Wait for sync
    for i in {1..30}; do
        SYNC_STATUS=$(kubectl get application ecommerce-dev -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        if [ "$SYNC_STATUS" = "Synced" ]; then
            echo -e "${GREEN}✓ Application synced successfully${NC}"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
    
else
    # Direct kubectl deployment
    echo "Deploying via kubectl..."
    kubectl apply -k gitops/overlays/dev
    
    echo ""
    echo -e "${GREEN}✓ Application deployed${NC}"
fi

echo ""

# Update ConfigMap with actual values from frontend-secrets.env
echo "Updating frontend-config with actual values..."
kubectl create configmap frontend-config \
  --from-env-file=gitops/overlays/dev/frontend-secrets.env \
  -n ecommerce-dev \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

echo -e "${GREEN}✓ ConfigMap updated${NC}"
echo ""

# Step 4: Wait for pods to be ready
echo -e "${GREEN}Step 4: Waiting for Pods to be Ready${NC}"
echo "-------------------------------------"
echo ""

echo "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n ecommerce-dev --timeout=120s 2>/dev/null || true

echo "Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n ecommerce-dev --timeout=120s 2>/dev/null || true

echo "Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n ecommerce-dev --timeout=120s 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ All pods are ready${NC}"
echo ""

# Step 5: Display access information
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Installation Complete! 🎉${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Wait a moment for services to get NodePort assigned
echo "Retrieving service information..."
sleep 3

# Get NodePort info
FRONTEND_NODEPORT=$(kubectl get svc frontend -n ecommerce-dev -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
BACKEND_NODEPORT=$(kubectl get svc backend -n ecommerce-dev -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")

# Get ingress info
INGRESS_HOST=$(kubectl get ingress ecommerce-ingress -n ecommerce-dev -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "ecommerce-dev.local")

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}║  🌐  Access the E-Commerce Application UI:            ║${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
if [ "$FRONTEND_NODEPORT" != "N/A" ]; then
    printf "${GREEN}║      ${YELLOW}%-46s${GREEN}║${NC}\n" "http://${NODE_IP}:${FRONTEND_NODEPORT}"
else
    echo -e "${GREEN}║      ${RED}Waiting for NodePort assignment...${GREEN}         ║${NC}"
fi
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Additional Access Methods:${NC}"
echo ""
echo "  Via Ingress (if configured):"
echo "    Frontend: http://${INGRESS_HOST}/"
echo "    Backend:  http://${INGRESS_HOST}/api"
echo ""
echo "  Direct NodePort Access:"
if [ "$FRONTEND_NODEPORT" != "N/A" ]; then
    echo "    Frontend: http://${NODE_IP}:${FRONTEND_NODEPORT}"
else
    echo "    Frontend: (NodePort being assigned...)"
fi
if [ "$BACKEND_NODEPORT" != "N/A" ]; then
    echo "    Backend:  http://${NODE_IP}:${BACKEND_NODEPORT}"
else
    echo "    Backend:  (NodePort being assigned...)"
fi
echo ""

if [ "$DEPLOY_METHOD" = "1" ]; then
    echo -e "${GREEN}ArgoCD Application:${NC}"
    echo "  kubectl get application ecommerce-dev -n argocd"
    echo ""
fi

echo -e "${GREEN}Useful Commands:${NC}"
echo "  View info:        ./show-info.sh"
echo "  View pods:        kubectl get pods -n ecommerce-dev"
echo "  View logs:        kubectl logs -f <pod-name> -n ecommerce-dev"
echo "  Uninstall:        ./uninstall.sh"
echo ""

echo -e "${YELLOW}Note:${NC} If using Ingress, make sure to add '${INGRESS_HOST}' to your /etc/hosts file:"
echo "  echo \"${NODE_IP} ${INGRESS_HOST}\" | sudo tee -a /etc/hosts"
echo ""

echo -e "${GREEN}Installation completed successfully!${NC}"
echo ""
echo -e "${CYAN}💡 Tip: Run ${YELLOW}./show-info.sh${CYAN} anytime to view access URLs and installation details${NC}"
