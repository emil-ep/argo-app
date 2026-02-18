#!/bin/bash

# Enable Canary Deployments with Argo Rollouts
# This script installs Argo Rollouts and configures your application for canary deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Argo Rollouts Setup for Canary Deployments ===${NC}\n"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✓ kubectl is installed and cluster is accessible${NC}\n"

# Step 1: Install Argo Rollouts
echo -e "${YELLOW}Step 1: Installing Argo Rollouts...${NC}"

kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

echo -e "${YELLOW}Waiting for Argo Rollouts controller to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argo-rollouts -n argo-rollouts --timeout=120s

echo -e "${GREEN}✓ Argo Rollouts installed successfully${NC}\n"

# Step 2: Install kubectl plugin
echo -e "${YELLOW}Step 2: Installing kubectl-argo-rollouts plugin...${NC}"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH="arm64"
fi

PLUGIN_URL="https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-${OS}-${ARCH}"

echo -e "${YELLOW}Downloading from: $PLUGIN_URL${NC}"

if curl -LO "$PLUGIN_URL" 2>/dev/null; then
    chmod +x kubectl-argo-rollouts-${OS}-${ARCH}
    
    if [ -w "/usr/local/bin" ]; then
        mv kubectl-argo-rollouts-${OS}-${ARCH} /usr/local/bin/kubectl-argo-rollouts
    else
        sudo mv kubectl-argo-rollouts-${OS}-${ARCH} /usr/local/bin/kubectl-argo-rollouts
    fi
    
    echo -e "${GREEN}✓ kubectl-argo-rollouts plugin installed${NC}\n"
else
    echo -e "${YELLOW}⚠ Could not download plugin automatically${NC}"
    echo -e "${YELLOW}Please install manually from: https://github.com/argoproj/argo-rollouts/releases${NC}\n"
fi

# Step 3: Install Argo Rollouts Dashboard (optional)
read -p "Install Argo Rollouts Dashboard? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installing Argo Rollouts Dashboard...${NC}"
    kubectl apply -f https://github.com/argoproj/argo-rollouts/releases/latest/download/dashboard-install.yaml
    echo -e "${GREEN}✓ Dashboard installed${NC}"
    echo -e "${BLUE}Access dashboard with: kubectl port-forward -n argo-rollouts svc/argo-rollouts-dashboard 3100:3100${NC}\n"
fi

# Step 4: Configure backend for canary deployments
echo -e "${YELLOW}Step 3: Configuring backend for canary deployments...${NC}"

BACKEND_DIR="gitops/base/backend"

if [ ! -f "$BACKEND_DIR/kustomization.yaml" ]; then
    echo -e "${RED}Error: $BACKEND_DIR/kustomization.yaml not found${NC}"
    exit 1
fi

# Backup current kustomization
cp "$BACKEND_DIR/kustomization.yaml" "$BACKEND_DIR/kustomization-deployment.yaml.bak"
echo -e "${GREEN}✓ Backed up current kustomization${NC}"

# Use rollout configuration
cp "$BACKEND_DIR/kustomization-rollout.yaml" "$BACKEND_DIR/kustomization.yaml"
echo -e "${GREEN}✓ Switched to rollout configuration${NC}\n"

# Step 5: Delete existing deployment
echo -e "${YELLOW}Step 4: Removing existing deployment...${NC}"

NAMESPACE="ecommerce-dev"

if kubectl get deployment backend -n $NAMESPACE &> /dev/null; then
    kubectl delete deployment backend -n $NAMESPACE
    echo -e "${GREEN}✓ Existing deployment removed${NC}\n"
else
    echo -e "${YELLOW}⚠ No existing deployment found${NC}\n"
fi

# Step 6: Commit changes
echo -e "${YELLOW}Step 5: Committing changes...${NC}"

if git rev-parse --git-dir > /dev/null 2>&1; then
    git add "$BACKEND_DIR/kustomization.yaml"
    git commit -m "feat: enable canary deployments with Argo Rollouts" || true
    echo -e "${GREEN}✓ Changes committed${NC}\n"
    
    read -p "Push changes to remote? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin main || git push origin master
        echo -e "${GREEN}✓ Changes pushed${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ Not a git repository, skipping commit${NC}\n"
fi

# Step 7: Sync with ArgoCD
echo -e "${YELLOW}Step 6: Syncing with ArgoCD...${NC}"

if command -v argocd &> /dev/null; then
    argocd app sync ecommerce-dev
    echo -e "${GREEN}✓ ArgoCD synced${NC}\n"
else
    echo -e "${YELLOW}⚠ argocd CLI not found${NC}"
    echo -e "${YELLOW}Please sync manually: argocd app sync ecommerce-dev${NC}\n"
fi

# Summary
echo -e "${GREEN}=== Setup Complete! ===${NC}\n"

echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. Verify rollout is created:"
echo -e "   ${YELLOW}kubectl argo rollouts get rollout backend -n $NAMESPACE${NC}"
echo -e ""
echo -e "2. Watch rollout status:"
echo -e "   ${YELLOW}kubectl argo rollouts get rollout backend -n $NAMESPACE --watch${NC}"
echo -e ""
echo -e "3. Trigger a canary deployment by updating the image tag in:"
echo -e "   ${YELLOW}gitops/overlays/dev/kustomization.yaml${NC}"
echo -e ""
echo -e "4. Access dashboard (if installed):"
echo -e "   ${YELLOW}kubectl port-forward -n argo-rollouts svc/argo-rollouts-dashboard 3100:3100${NC}"
echo -e "   ${YELLOW}Open: http://localhost:3100${NC}"
echo -e ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "   ${YELLOW}docs/CANARY-DEPLOYMENT.md${NC}"
echo -e ""
echo -e "${GREEN}Happy deploying! 🚀${NC}"

# Made with Bob
