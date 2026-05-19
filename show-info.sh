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
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")

# Get NodePort info
FRONTEND_NODEPORT=$(kubectl get svc frontend -n ecommerce-dev -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
BACKEND_NODEPORT=$(kubectl get svc backend -n ecommerce-dev -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

# Get ingress info
INGRESS_HOST=$(kubectl get ingress ecommerce-ingress -n ecommerce-dev -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "N/A")

# Display main access URL
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}║  🌐  Access the E-Commerce Application UI:            ║${NC}"
echo -e "${GREEN}║                                                        ║${NC}"
if [ "$FRONTEND_NODEPORT" != "N/A" ]; then
    printf "${GREEN}║      ${YELLOW}%-46s${GREEN}║${NC}\n" "http://${NODE_IP}:${FRONTEND_NODEPORT}"
else
    echo -e "${GREEN}║      ${RED}Frontend service not found${GREEN}                     ║${NC}"
fi
echo -e "${GREEN}║                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Pod Status
echo -e "${CYAN}Pod Status:${NC}"
echo "----------------------------"
kubectl get pods -n ecommerce-dev -o wide 2>/dev/null || echo "No pods found"
echo ""

# Service Information
echo -e "${CYAN}Service Information:${NC}"
echo "----------------------------"
echo -e "Frontend NodePort: ${YELLOW}${FRONTEND_NODEPORT}${NC}"
echo -e "Backend NodePort:  ${YELLOW}${BACKEND_NODEPORT}${NC}"
echo ""

# Access URLs
echo -e "${CYAN}Access URLs:${NC}"
echo "----------------------------"
if [ "$FRONTEND_NODEPORT" != "N/A" ]; then
    echo -e "Frontend (NodePort): ${GREEN}http://${NODE_IP}:${FRONTEND_NODEPORT}${NC}"
fi
if [ "$BACKEND_NODEPORT" != "N/A" ]; then
    echo -e "Backend (NodePort):  ${GREEN}http://${NODE_IP}:${BACKEND_NODEPORT}${NC}"
fi
if [ "$INGRESS_HOST" != "N/A" ]; then
    echo ""
    echo "Via Ingress:"
    echo -e "  Frontend: ${GREEN}http://${INGRESS_HOST}/${NC}"
    echo -e "  Backend:  ${GREEN}http://${INGRESS_HOST}/api${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} Add to /etc/hosts: ${NODE_IP} ${INGRESS_HOST}"
fi
echo ""

# ArgoCD Application Status (if exists)
if kubectl get application ecommerce-dev -n argocd &> /dev/null; then
    echo -e "${CYAN}ArgoCD Application:${NC}"
    echo "----------------------------"
    SYNC_STATUS=$(kubectl get application ecommerce-dev -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH_STATUS=$(kubectl get application ecommerce-dev -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    echo -e "Sync Status:   ${YELLOW}${SYNC_STATUS}${NC}"
    echo -e "Health Status: ${YELLOW}${HEALTH_STATUS}${NC}"
    echo ""
fi

# Useful Commands
echo -e "${CYAN}Useful Commands:${NC}"
echo "----------------------------"
echo "  View pods:           kubectl get pods -n ecommerce-dev"
echo "  View services:       kubectl get svc -n ecommerce-dev"
echo "  View logs (frontend): kubectl logs -f deployment/frontend -n ecommerce-dev"
echo "  View logs (backend):  kubectl logs -f deployment/backend -n ecommerce-dev"
echo "  Restart frontend:    kubectl rollout restart deployment/frontend -n ecommerce-dev"
echo "  Restart backend:     kubectl rollout restart deployment/backend -n ecommerce-dev"
echo "  Uninstall:           ./uninstall.sh"
echo ""

echo -e "${GREEN}For more details, check the documentation in the docs/ directory.${NC}"

# Made with Bob
