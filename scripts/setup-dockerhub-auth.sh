#!/bin/bash

# Setup Docker Hub Authentication for Kubernetes
# This script creates a docker-registry secret to avoid Docker Hub rate limits

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Docker Hub Authentication Setup ===${NC}\n"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Get namespace
read -p "Enter namespace (default: ecommerce-dev): " NAMESPACE
NAMESPACE=${NAMESPACE:-ecommerce-dev}

# Get Docker Hub credentials
echo -e "\n${YELLOW}Enter your Docker Hub credentials:${NC}"
echo "If you don't have an account, create one at https://hub.docker.com/signup"
echo ""

read -p "Docker Hub Username: " DOCKERHUB_USERNAME
read -sp "Docker Hub Password/Token: " DOCKERHUB_PASSWORD
echo ""
read -p "Email: " DOCKERHUB_EMAIL

# Validate inputs
if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_PASSWORD" ] || [ -z "$DOCKERHUB_EMAIL" ]; then
    echo -e "${RED}Error: All fields are required${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Creating namespace if it doesn't exist...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo -e "${YELLOW}Creating docker-registry secret...${NC}"
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=$DOCKERHUB_USERNAME \
  --docker-password=$DOCKERHUB_PASSWORD \
  --docker-email=$DOCKERHUB_EMAIL \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker Hub authentication configured successfully!${NC}\n"
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Uncomment imagePullSecrets in gitops/base/database/statefulset.yaml"
    echo "2. Commit and push changes"
    echo "3. ArgoCD will sync automatically"
    echo ""
    echo -e "${GREEN}Or apply immediately:${NC}"
    echo "kubectl apply -k gitops/overlays/dev/"
else
    echo -e "${RED}✗ Failed to create secret${NC}"
    exit 1
fi

# Made with Bob
