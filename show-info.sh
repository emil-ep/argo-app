#!/bin/bash

# E-Commerce Application Info Script
# Displays installation details and access URLs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  E-Commerce Application Info${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if namespace exists
if ! kubectl get namespace ecommerce-dev &> /dev/null; then
    echo -e "${RED}Error: ecommerce-dev namespace not found${NC}"
    echo "The application may not be installed yet."
    echo "Run ./install.sh to install the application."
    exit 1
fi

# Get node IP
NODE_IP=$(kubectl get nodes \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' \
  2>/dev/null || echo "localhost")

# Get Traefik NodePort
TRAEFIK_PORT=$(kubectl get svc traefik -n kube-system \
  -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || echo "")

# Get frontend NodePort
FRONTEND_NODEPORT=$(kubectl get svc frontend -n ecommerce-dev \
  -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

# Get ingress host
INGRESS_HOST=$(kubectl get ingress ecommerce-ingress -n ecommerce-dev \
  -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "N/A")

# Display main access URL
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}║  🌐  Access the E-Commerce Application:               ║${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
if [ -n "$TRAEFIK_PORT" ] && [ "$NODE_IP" != "localhost" ]; then
    printf "${GREEN}║  Via Ingress (recommended):                            ║${NC}\n"
    printf "${GREEN}║      ${YELLOW}%-46s${GREEN}║${NC}\n" "http://${NODE_IP}:${TRAEFIK_PORT}"
fi
if [ "$FRONTEND_NODEPORT" != "N/A" ]; then
    printf "${GREEN}║  Via NodePort (direct):                                ║${NC}\n"
    printf "${GREEN}║      ${YELLOW}%-46s${GREEN}║${NC}\n" "http://${NODE_IP}:${FRONTEND_NODEPORT}"
fi
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Pod Status
echo -e "${CYAN}Pod Status:${NC}"
echo "----------------------------"
kubectl get pods -n ecommerce-dev -o wide 2>/dev/null || echo "No pods found"
echo ""

# Rollout Status
echo -e "${CYAN}Backend Rollout Status:${NC}"
echo "----------------------------"
kubectl get rollout backend -n ecommerce-dev 2>/dev/null || echo "No rollout found"
echo ""

# Service Information
echo -e "${CYAN}Service Information:${NC}"
echo "----------------------------"
kubectl get svc -n ecommerce-dev 2>/dev/null || echo "No services found"
echo ""

# Ingress
echo -e "${CYAN}Ingress:${NC}"
echo "----------------------------"
kubectl get ingress -n ecommerce-dev 2>/dev/null || echo "No ingresses found"
echo ""

# ArgoCD Application Status (if exists)
if kubectl get application ecommerce-dev -n argocd &> /dev/null 2>&1; then
    echo -e "${CYAN}ArgoCD Application:${NC}"
    echo "----------------------------"
    SYNC_STATUS=$(kubectl get application ecommerce-dev -n argocd \
      -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH_STATUS=$(kubectl get application ecommerce-dev -n argocd \
      -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    echo -e "Sync Status:   ${YELLOW}${SYNC_STATUS}${NC}"
    echo -e "Health Status: ${YELLOW}${HEALTH_STATUS}${NC}"
    echo ""
fi

# Useful Commands
echo -e "${CYAN}Useful Commands:${NC}"
echo "----------------------------"
echo "  View pods:             kubectl get pods -n ecommerce-dev"
echo "  View services:         kubectl get svc -n ecommerce-dev"
echo "  View rollout:          kubectl get rollout backend -n ecommerce-dev"
echo "  Logs (frontend):       kubectl logs -f deployment/frontend -n ecommerce-dev"
echo "  Logs (backend):        kubectl logs -f -l app=backend -n ecommerce-dev"
echo "  Restart frontend:      kubectl rollout restart deployment/frontend -n ecommerce-dev"
echo "  Restart backend:       kubectl patch rollout backend -n ecommerce-dev --type merge -p '{\"spec\":{\"restartAt\":\"'\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"'\"}}'"
echo "  Uninstall:             ./uninstall.sh"
echo ""

if [ "$INGRESS_HOST" != "N/A" ]; then
    echo -e "${YELLOW}Note:${NC} To use hostname '${INGRESS_HOST}', add to /etc/hosts:"
    echo "  echo \"${NODE_IP} ${INGRESS_HOST}\" | sudo tee -a /etc/hosts"
    echo ""
fi

echo -e "${GREEN}For more details, check the documentation in the docs/ directory.${NC}"
echo ""

# Made with Bob
