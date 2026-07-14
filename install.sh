#!/bin/bash

# E-Commerce Application Installation Script
# This script automates the complete installation process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Check if Argo Rollouts is installed
if kubectl get namespace argo-rollouts &> /dev/null; then
    echo "  ✓ Argo Rollouts detected"
else
    echo -e "  ${RED}Error: argo-rollouts namespace not found.${NC}"
    echo "  Argo Rollouts must be installed before running this script."
    echo "  Install it with:"
    echo "    kubectl create namespace argo-rollouts"
    echo "    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml"
    exit 1
fi

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

if [ -f "gitops/overlays/dev/secrets.env" ]; then
    echo -e "${YELLOW}Secret file already exists.${NC}"
    read -p "Do you want to reconfigure secrets? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/setup-secrets.sh
    else
        echo "Using existing secret file..."
    fi
else
    ./scripts/setup-secrets.sh
fi

echo ""

# Step 2: Create Kubernetes namespace, secrets, and configmaps
echo -e "${GREEN}Step 2: Creating Namespace, Secrets & ConfigMaps${NC}"
echo "-------------------------------------------------"
echo ""

# Create namespace
echo "Creating namespace..."
kubectl create namespace ecommerce-dev --dry-run=client -o yaml | kubectl apply -f -

# Create backend secret from secrets.env
echo "Creating backend-secret..."
kubectl create secret generic backend-secret \
  --from-env-file=gitops/overlays/dev/secrets.env \
  -n ecommerce-dev \
  --dry-run=client -o yaml | kubectl apply -f -

# Create instana-credentials secret for the Argo Rollouts AnalysisTemplate.
# serverUrl, apiToken, and clusterName are stored as Secret keys because Argo
# Rollouts analysis args only support secretKeyRef (not configMapKeyRef) for valueFrom.
echo "Creating instana-credentials secret..."
INSTANA_API_TOKEN=$(grep '^instana.api.token=' gitops/overlays/dev/secrets.env \
  | cut -d= -f2- | tr -d '[:space:]')
INSTANA_SERVER_URL=$(grep '^instana.server.url=' gitops/overlays/dev/secrets.env \
  | cut -d= -f2- | tr -d '[:space:]')
INSTANA_CLUSTER_NAME=$(grep '^instana.cluster.name=' gitops/overlays/dev/secrets.env \
  | cut -d= -f2- | tr -d '[:space:]')
if [ -n "$INSTANA_API_TOKEN" ] && [ -n "$INSTANA_SERVER_URL" ] && [ -n "$INSTANA_CLUSTER_NAME" ]; then
    kubectl create secret generic instana-credentials \
      --from-literal=apiToken="$INSTANA_API_TOKEN" \
      --from-literal=serverUrl="$INSTANA_SERVER_URL" \
      --from-literal=clusterName="$INSTANA_CLUSTER_NAME" \
      -n ecommerce-dev \
      --dry-run=client -o yaml | kubectl apply -f -
    echo -e "${GREEN}✓ instana-credentials secret created (serverUrl + apiToken + clusterName)${NC}"
else
    [ -z "$INSTANA_API_TOKEN" ]   && echo -e "${YELLOW}⚠ instana.api.token not found in secrets.env${NC}"
    [ -z "$INSTANA_SERVER_URL" ]  && echo -e "${YELLOW}⚠ instana.server.url not found in secrets.env${NC}"
    [ -z "$INSTANA_CLUSTER_NAME" ] && echo -e "${YELLOW}⚠ instana.cluster.name not found in secrets.env${NC}"
    echo -e "${YELLOW}  The canary analysis will fail until instana-credentials secret is created.${NC}"
fi

# Register the Instana Rollouts metric plugin with the Argo Rollouts controller.
# This ConfigMap tells the controller the binary location to download at startup.
# Without this, any AnalysisRun using instana/rollouts-plugin will fail immediately.
echo "Registering Instana Rollouts plugin with Argo Rollouts controller..."
kubectl apply -f gitops/base/argo-rollouts/plugin-configmap.yaml
echo -e "${GREEN}✓ Argo Rollouts plugin configmap applied${NC}"
echo -e "${YELLOW}  Note: The controller will download the plugin binary on its next restart.${NC}"
echo -e "${YELLOW}  Restart it now to ensure the plugin is ready before the first rollout:${NC}"
echo -e "${YELLOW}    kubectl rollout restart deployment/argo-rollouts -n argo-rollouts${NC}"
echo ""

echo -e "${GREEN}✓ Namespace, secrets and configmaps ready${NC}"
echo ""

# Step 3: Deploy application
echo -e "${GREEN}Step 3: Deploying Application${NC}"
echo "------------------------------"
echo ""

if [ "$DEPLOY_METHOD" = "1" ]; then
    # ArgoCD deployment
    echo "Deploying via ArgoCD..."

    kubectl apply -f gitops/argocd/application.yaml

    echo ""
    echo -e "${GREEN}✓ ArgoCD Application created${NC}"
    echo ""
    echo "Waiting for ArgoCD to sync..."
    sleep 5

    # Trigger sync against the current HEAD of the default branch
    kubectl patch application ecommerce-dev -n argocd \
      --type merge \
      -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}' 2>/dev/null || true

    echo ""
    echo -e "${YELLOW}Monitoring deployment (this may take 1-2 minutes)...${NC}"

    # Wait for sync
    for i in {1..30}; do
        SYNC_STATUS=$(kubectl get application ecommerce-dev -n argocd \
          -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
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

# Step 4: Wait for pods to be ready
echo -e "${GREEN}Step 4: Waiting for Pods to be Ready${NC}"
echo "-------------------------------------"
echo ""

echo "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n ecommerce-dev --timeout=120s 2>/dev/null || true

# Kick the Rollout if it has no current pods (can happen after a namespace reset)
ROLLOUT_CURRENT=$(kubectl get rollout backend -n ecommerce-dev \
  -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
if [ "${ROLLOUT_CURRENT:-0}" = "0" ]; then
    echo "Restarting stalled backend rollout..."
    kubectl patch rollout backend -n ecommerce-dev \
      --type merge \
      -p '{"spec":{"restartAt":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}}' 2>/dev/null || true
fi

echo "Waiting for backend to be ready..."
for i in {1..60}; do
    READY=$(kubectl get pods -n ecommerce-dev -l app=backend \
      --field-selector=status.phase=Running \
      -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null \
      | tr ' ' '\n' | grep -c true || echo 0)
    if [ "${READY}" -gt "0" ]; then
        echo -e "${GREEN}✓ Backend ready (${READY} pods)${NC}"
        break
    fi
    echo -n "."
    sleep 3
done
echo ""

echo "Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n ecommerce-dev --timeout=120s 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ All pods are ready${NC}"
echo ""

# Step 5: Patch frontend-config with the backend NodePort URL
echo -e "${GREEN}Step 5: Configuring Frontend API URL${NC}"
echo "-------------------------------------"
echo ""

# Get node IP
NODE_IP=$(kubectl get nodes \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' \
  2>/dev/null || echo "localhost")

# Get backend NodePort (defined as 30300 in service.yaml)
BACKEND_NODEPORT=$(kubectl get svc backend -n ecommerce-dev \
  -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30300")

# Get frontend NodePort
FRONTEND_NODEPORT=$(kubectl get svc frontend -n ecommerce-dev \
  -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

API_URL="http://${NODE_IP}:${BACKEND_NODEPORT}"

echo "Patching frontend-config api.url to ${API_URL}..."
kubectl patch configmap frontend-config -n ecommerce-dev \
  --type merge \
  -p "{\"data\":{\"api.url\":\"${API_URL}\"}}" 2>/dev/null || true
echo -e "${GREEN}✓ frontend-config api.url updated${NC}"

# Restart frontend so the new API_URL env value is picked up
echo "Restarting frontend to pick up new api.url..."
kubectl rollout restart deployment/frontend -n ecommerce-dev 2>/dev/null || true
kubectl rollout status deployment/frontend -n ecommerce-dev --timeout=60s 2>/dev/null || true
echo -e "${GREEN}✓ Frontend restarted${NC}"
echo ""

# Step 6: Display access information
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Installation Complete! 🎉${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}║  🌐  Access the E-Commerce Application:               ║${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
printf "${GREEN}║  Frontend:  ${YELLOW}%-43s${GREEN}║${NC}\n" "http://${NODE_IP}:${FRONTEND_NODEPORT}"
printf "${GREEN}║  Backend:   ${YELLOW}%-43s${GREEN}║${NC}\n" "http://${NODE_IP}:${BACKEND_NODEPORT}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DEPLOY_METHOD" = "1" ]; then
    echo -e "${CYAN}ArgoCD Application:${NC}"
    echo "  kubectl get application ecommerce-dev -n argocd"
    echo ""
fi

echo -e "${CYAN}Useful Commands:${NC}"
echo "  View info:     ./show-info.sh"
echo "  View pods:     kubectl get pods -n ecommerce-dev"
echo "  View logs:     kubectl logs -f <pod-name> -n ecommerce-dev"
echo "  Uninstall:     ./uninstall.sh"
echo ""

echo -e "${GREEN}Installation completed successfully!${NC}"
echo ""
echo -e "${CYAN}💡 Tip: Run ${YELLOW}./show-info.sh${CYAN} anytime to view access URLs and status.${NC}"
echo ""
