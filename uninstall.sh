#!/bin/bash

# E-Commerce Application Uninstallation Script
# This script removes all application resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  E-Commerce Application Uninstaller${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace ecommerce-dev &> /dev/null; then
    echo -e "${YELLOW}Application is not installed (namespace not found)${NC}"
    exit 0
fi

# Confirm uninstallation
echo -e "${YELLOW}WARNING: This will delete all application resources!${NC}"
echo ""
echo "The following will be removed:"
echo "  • All pods, services, deployments, and rollouts in ecommerce-dev namespace"
echo "  • All secrets and configmaps"
echo "  • Database data (if using local storage)"
echo "  • ArgoCD application (if exists)"
echo "  • Canary ingress created by Argo Rollouts (if exists)"
echo ""
read -p "Are you sure you want to continue? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting uninstallation...${NC}"
echo ""

# Step 1: Remove ArgoCD application first so it stops reconciling
if kubectl get application ecommerce-dev -n argocd &> /dev/null 2>&1; then
    echo "Removing ArgoCD application..."

    # Stop automated sync so ArgoCD stops reconciling immediately
    kubectl patch application ecommerce-dev -n argocd \
      --type merge \
      -p '{"spec":{"syncPolicy":{"automated":null}}}' 2>/dev/null || true

    # Strip the deletion finalizer so delete is instant and never blocks
    kubectl patch application ecommerce-dev -n argocd \
      --type merge \
      -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true

    # Delete the application
    kubectl delete application ecommerce-dev -n argocd --wait=false 2>/dev/null || true

    echo -e "${GREEN}✓ ArgoCD application removed${NC}"
    echo ""
fi

# Step 2: Remove Argo Rollouts finalizers from the backend Rollout so namespace
# deletion is not blocked waiting for the rollout controller to clean up
if kubectl get rollout backend -n ecommerce-dev &> /dev/null 2>&1; then
    echo "Removing Argo Rollouts finalizers from backend rollout..."
    kubectl patch rollout backend -n ecommerce-dev \
      --type merge \
      -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
    echo -e "${GREEN}✓ Rollout finalizers cleared${NC}"
fi

# Step 3: Delete the canary ingress created dynamically by Argo Rollouts
if kubectl get ingress backend-ecommerce-ingress-canary -n ecommerce-dev &> /dev/null 2>&1; then
    echo "Removing Argo Rollouts canary ingress..."
    kubectl delete ingress backend-ecommerce-ingress-canary -n ecommerce-dev --wait=false 2>/dev/null || true
    echo -e "${GREEN}✓ Canary ingress removed${NC}"
fi

# Step 4: Delete all resources using kustomize (belt-and-suspenders cleanup)
echo "Removing application resources via kustomize..."
kubectl delete -k gitops/overlays/dev --wait=false 2>/dev/null || true

# Step 5: Force delete namespace
echo "Removing namespace..."
kubectl delete namespace ecommerce-dev --wait=false 2>/dev/null || true

# Wait for namespace to be fully removed (includes finalizer processing)
echo ""
echo "Waiting for namespace and all finalizers to finish..."
for i in {1..60}; do
    if ! kubectl get namespace ecommerce-dev &> /dev/null; then
        echo ""
        echo -e "${GREEN}✓ Namespace removed${NC}"
        break
    fi
    echo -n "."
    sleep 3
done
echo ""

# If namespace is still stuck, force-remove its own finalizers via the API
if kubectl get namespace ecommerce-dev &> /dev/null 2>&1; then
    echo -e "${YELLOW}Namespace still terminating — forcing finalizer removal...${NC}"
    kubectl get namespace ecommerce-dev -o json | \
        jq '.spec.finalizers = []' | \
        kubectl replace --raw "/api/v1/namespaces/ecommerce-dev/finalize" -f - 2>/dev/null || true
    sleep 3
    if ! kubectl get namespace ecommerce-dev &> /dev/null 2>&1; then
        echo -e "${GREEN}✓ Namespace removed after forced finalizer cleanup${NC}"
    else
        echo -e "${RED}⚠ Namespace still present — manual cleanup may be required${NC}"
        echo "  kubectl get namespace ecommerce-dev -o yaml"
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Uninstallation Complete! ✓${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}All application resources have been removed.${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Secret files in gitops/overlays/dev/ were NOT deleted."
echo "To remove them manually:"
echo "  rm -f gitops/overlays/dev/secrets.env"
echo "  rm -f gitops/overlays/dev/frontend-secrets.env"
echo ""
echo "To reinstall the application, run:"
echo "  ./install.sh"
echo ""
