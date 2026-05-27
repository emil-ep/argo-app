#!/bin/bash

# Instana Configuration Checker
# This script verifies Instana configuration in the deployed application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Instana Configuration Checker${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if namespace exists
if ! kubectl get namespace ecommerce-dev &> /dev/null; then
    echo -e "${RED}Error: ecommerce-dev namespace not found${NC}"
    exit 1
fi

echo -e "${CYAN}Checking Backend Configuration...${NC}"
echo "-----------------------------------"

# Get backend pod
BACKEND_POD=$(kubectl get pods -n ecommerce-dev -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$BACKEND_POD" ]; then
    echo -e "${RED}✗ No backend pod found${NC}"
else
    echo -e "${GREEN}✓ Backend pod: ${BACKEND_POD}${NC}"
    echo ""
    
    # Check environment variables
    echo -e "${YELLOW}Environment Variables:${NC}"
    
    INSTANA_ENABLED=$(kubectl exec -n ecommerce-dev $BACKEND_POD -- printenv INSTANA_ENABLED 2>/dev/null || echo "NOT SET")
    INSTANA_AGENT_HOST=$(kubectl exec -n ecommerce-dev $BACKEND_POD -- printenv INSTANA_AGENT_HOST 2>/dev/null || echo "NOT SET")
    INSTANA_AGENT_PORT=$(kubectl exec -n ecommerce-dev $BACKEND_POD -- printenv INSTANA_AGENT_PORT 2>/dev/null || echo "NOT SET")
    INSTANA_AGENT_KEY=$(kubectl exec -n ecommerce-dev $BACKEND_POD -- printenv INSTANA_AGENT_KEY 2>/dev/null || echo "NOT SET")
    INSTANA_SERVICE_NAME=$(kubectl exec -n ecommerce-dev $BACKEND_POD -- printenv INSTANA_SERVICE_NAME 2>/dev/null || echo "NOT SET")
    
    echo "  INSTANA_ENABLED:      $INSTANA_ENABLED"
    echo "  INSTANA_AGENT_HOST:   $INSTANA_AGENT_HOST"
    echo "  INSTANA_AGENT_PORT:   $INSTANA_AGENT_PORT"
    echo "  INSTANA_SERVICE_NAME: $INSTANA_SERVICE_NAME"
    
    if [ "$INSTANA_AGENT_KEY" = "NOT SET" ]; then
        echo -e "  INSTANA_AGENT_KEY:    ${RED}NOT SET${NC}"
    elif [ "$INSTANA_AGENT_KEY" = "CHANGE_ME_INSTANA_AGENT_KEY" ]; then
        echo -e "  INSTANA_AGENT_KEY:    ${RED}PLACEHOLDER VALUE (not configured)${NC}"
    else
        echo -e "  INSTANA_AGENT_KEY:    ${GREEN}SET (${#INSTANA_AGENT_KEY} chars)${NC}"
    fi
    
    echo ""
    
    # Check logs for Instana initialization
    echo -e "${YELLOW}Checking Backend Logs:${NC}"
    INSTANA_LOG=$(kubectl logs -n ecommerce-dev $BACKEND_POD --tail=100 2>/dev/null | grep -i "instana" || echo "")
    
    if [ -z "$INSTANA_LOG" ]; then
        echo -e "${RED}✗ No Instana initialization messages found${NC}"
    else
        echo -e "${GREEN}✓ Instana messages found:${NC}"
        echo "$INSTANA_LOG" | head -5
    fi
    
    echo ""
    
    # Check for errors
    echo -e "${YELLOW}Checking for Errors:${NC}"
    ERROR_LOG=$(kubectl logs -n ecommerce-dev $BACKEND_POD --tail=100 2>/dev/null | grep -i "error\|fail\|warn" | grep -i "instana" || echo "")
    
    if [ -z "$ERROR_LOG" ]; then
        echo -e "${GREEN}✓ No Instana-related errors found${NC}"
    else
        echo -e "${RED}✗ Errors found:${NC}"
        echo "$ERROR_LOG"
    fi
fi

echo ""
echo -e "${CYAN}Checking Frontend Configuration...${NC}"
echo "-----------------------------------"

# Get frontend pod
FRONTEND_POD=$(kubectl get pods -n ecommerce-dev -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$FRONTEND_POD" ]; then
    echo -e "${RED}✗ No frontend pod found${NC}"
else
    echo -e "${GREEN}✓ Frontend pod: ${FRONTEND_POD}${NC}"
    echo ""
    
    # Check environment variables
    echo -e "${YELLOW}Environment Variables:${NC}"
    
    API_URL=$(kubectl exec -n ecommerce-dev $FRONTEND_POD -- printenv API_URL 2>/dev/null || echo "NOT SET")
    INSTANA_EUM_KEY=$(kubectl exec -n ecommerce-dev $FRONTEND_POD -- printenv INSTANA_EUM_KEY 2>/dev/null || echo "NOT SET")
    INSTANA_EUM_URL=$(kubectl exec -n ecommerce-dev $FRONTEND_POD -- printenv INSTANA_EUM_URL 2>/dev/null || echo "NOT SET")
    
    echo "  API_URL:          $API_URL"
    echo "  INSTANA_EUM_URL:  $INSTANA_EUM_URL"
    
    if [ "$INSTANA_EUM_KEY" = "NOT SET" ]; then
        echo -e "  INSTANA_EUM_KEY:  ${RED}NOT SET${NC}"
    elif [ "$INSTANA_EUM_KEY" = "CHANGE_ME_INSTANA_EUM_KEY" ]; then
        echo -e "  INSTANA_EUM_KEY:  ${RED}PLACEHOLDER VALUE (not configured)${NC}"
    else
        echo -e "  INSTANA_EUM_KEY:  ${GREEN}SET (${#INSTANA_EUM_KEY} chars)${NC}"
    fi
fi

echo ""
echo -e "${CYAN}Checking Secrets...${NC}"
echo "-----------------------------------"

# Check backend secret
if kubectl get secret backend-secret -n ecommerce-dev &> /dev/null; then
    echo -e "${GREEN}✓ backend-secret exists${NC}"
    
    # Check if keys exist
    KEYS=$(kubectl get secret backend-secret -n ecommerce-dev -o jsonpath='{.data}' | grep -o '"[^"]*":' | tr -d '":' || echo "")
    echo "  Keys: $KEYS"
else
    echo -e "${RED}✗ backend-secret not found${NC}"
fi

echo ""

# Check frontend configmap
if kubectl get configmap frontend-config -n ecommerce-dev &> /dev/null; then
    echo -e "${GREEN}✓ frontend-config exists${NC}"
    
    # Check if keys exist
    KEYS=$(kubectl get configmap frontend-config -n ecommerce-dev -o jsonpath='{.data}' | grep -o '"[^"]*":' | tr -d '":' || echo "")
    echo "  Keys: $KEYS"
else
    echo -e "${RED}✗ frontend-config not found${NC}"
fi

echo ""
echo -e "${CYAN}Recommendations:${NC}"
echo "-----------------------------------"

if [ "$INSTANA_AGENT_KEY" = "CHANGE_ME_INSTANA_AGENT_KEY" ] || [ "$INSTANA_AGENT_KEY" = "NOT SET" ]; then
    echo -e "${YELLOW}1. Configure backend Instana agent key:${NC}"
    echo "   - Edit gitops/overlays/dev/secrets.env"
    echo "   - Set instana.agent.key to your actual Instana agent key"
    echo "   - Run: kubectl create secret generic backend-secret --from-env-file=gitops/overlays/dev/secrets.env -n ecommerce-dev --dry-run=client -o yaml | kubectl apply -f -"
    echo "   - Restart backend: kubectl rollout restart deployment/backend -n ecommerce-dev"
    echo ""
fi

if [ "$INSTANA_EUM_KEY" = "CHANGE_ME_INSTANA_EUM_KEY" ] || [ "$INSTANA_EUM_KEY" = "NOT SET" ]; then
    echo -e "${YELLOW}2. Configure frontend Instana EUM key:${NC}"
    echo "   - Edit gitops/overlays/dev/frontend-secrets.env"
    echo "   - Set instana.eum.key to your actual Instana EUM key"
    echo "   - Run: kubectl create configmap frontend-config --from-env-file=gitops/overlays/dev/frontend-secrets.env -n ecommerce-dev --dry-run=client -o yaml | kubectl apply -f -"
    echo "   - Restart frontend: kubectl rollout restart deployment/frontend -n ecommerce-dev"
    echo ""
fi

if [ "$INSTANA_AGENT_HOST" = "NOT SET" ] || [ "$INSTANA_AGENT_HOST" = "CHANGE_ME_INSTANA_ENDPOINT_HOST" ]; then
    echo -e "${YELLOW}3. Configure Instana agent host:${NC}"
    echo "   - Edit gitops/overlays/dev/secrets.env"
    echo "   - Set instana.agent.host to your Instana endpoint (e.g., ingress-red-saas.instana.io)"
    echo ""
fi

echo -e "${GREEN}For more details, see: docs/INSTANA-SETUP.md${NC}"

# Made with Bob
