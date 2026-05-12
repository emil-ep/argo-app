#!/bin/bash

# Setup Secrets Script
# This script helps you configure Instana keys and other secrets for the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  E-Commerce Application Secrets Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Navigate to the overlay directory
OVERLAY_DIR="gitops/overlays/dev"

if [ ! -d "$OVERLAY_DIR" ]; then
    echo -e "${RED}Error: Directory $OVERLAY_DIR not found!${NC}"
    echo "Please run this script from the project root directory."
    exit 1
fi

cd "$OVERLAY_DIR"

# Check if secrets files already exist
if [ -f "secrets.env" ] || [ -f "frontend-secrets.env" ]; then
    echo -e "${YELLOW}Warning: Secret files already exist!${NC}"
    read -p "Do you want to overwrite them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo -e "${GREEN}Step 1: Backend Secrets Configuration${NC}"
echo "--------------------------------------"
echo ""

# Backend secrets
echo "Creating backend secrets file..."

# Database password
read -sp "Enter database password (or press Enter for default): " DB_PASSWORD
echo
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD="jjksdj112n_12mD!#"
    echo -e "${YELLOW}Using default database password${NC}"
fi

# JWT secret
read -sp "Enter JWT secret (or press Enter to generate): " JWT_SECRET
echo
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "adfhjdf@1!@hjsklasd")
    echo -e "${YELLOW}Generated JWT secret${NC}"
fi

# Instana agent key
echo ""
echo -e "${YELLOW}Get your Instana Agent Key from:${NC}"
echo "  Instana UI → Settings → Agent Keys"
echo ""
read -p "Enter Instana Agent Key: " INSTANA_AGENT_KEY

if [ -z "$INSTANA_AGENT_KEY" ]; then
    echo -e "${RED}Error: Instana Agent Key is required!${NC}"
    exit 1
fi

# Create backend secrets file
cat > secrets.env << EOF
# Backend Secrets Configuration
# Generated on $(date)

# Database credentials
database.user=postgres
database.password=$DB_PASSWORD

# JWT secret for authentication
jwt.secret=$JWT_SECRET

# Instana agent key for backend APM tracing
instana.agent.key=$INSTANA_AGENT_KEY
EOF

echo -e "${GREEN}✓ Backend secrets file created${NC}"
echo ""

# Frontend secrets
echo -e "${GREEN}Step 2: Frontend Secrets Configuration${NC}"
echo "---------------------------------------"
echo ""
echo -e "${YELLOW}Get your Instana EUM Key from:${NC}"
echo "  Instana UI → Settings → Websites & Mobile Apps"
echo ""
read -p "Enter Instana EUM Key: " INSTANA_EUM_KEY

if [ -z "$INSTANA_EUM_KEY" ]; then
    echo -e "${RED}Error: Instana EUM Key is required!${NC}"
    exit 1
fi

# Create frontend secrets file
cat > frontend-secrets.env << EOF
# Frontend Secrets Configuration
# Generated on $(date)

# Instana End User Monitoring (EUM) key
instana.eum.key=$INSTANA_EUM_KEY
EOF

echo -e "${GREEN}✓ Frontend secrets file created${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Secret files created:"
echo "  ✓ $OVERLAY_DIR/secrets.env"
echo "  ✓ $OVERLAY_DIR/frontend-secrets.env"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  • These files are gitignored and will NOT be committed"
echo "  • Keep these files secure and never share them"
echo "  • You can now deploy the application with:"
echo ""
echo "    kubectl apply -k $OVERLAY_DIR"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Review the generated files if needed"
echo "  2. Deploy the application using kubectl or ArgoCD"
echo "  3. See QUICKSTART.md for deployment instructions"
echo ""

# Made with Bob
