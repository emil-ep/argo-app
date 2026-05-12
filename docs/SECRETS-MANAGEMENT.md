# Secrets Management Guide

This guide explains how secrets are managed in this application, particularly for Instana monitoring keys.

## Overview

The application uses **Kustomize secretGenerator** to manage secrets securely. This approach ensures:

- ✅ Secrets are never committed to version control
- ✅ Each environment can have different secrets
- ✅ Easy credential rotation
- ✅ Secure deployment process
- ✅ GitOps-friendly workflow

## Quick Start

### Automated Setup (Recommended)

Use the provided script to configure all secrets interactively:

```bash
./scripts/setup-secrets.sh
```

The script will:
1. Prompt for database password (or use default)
2. Generate or accept a JWT secret
3. Ask for your Instana Agent Key
4. Ask for your Instana EUM Key
5. Create the necessary `.env` files

### Manual Setup

If you prefer to configure secrets manually:

```bash
# Navigate to the overlay directory
cd gitops/overlays/dev

# Copy templates
cp secrets.env.example secrets.env
cp frontend-secrets.env.example frontend-secrets.env

# Edit the files with your actual values
nano secrets.env
nano frontend-secrets.env
```

## Secret Files

### Backend Secrets (`secrets.env`)

Contains sensitive backend configuration:

```bash
# Database credentials
database.user=postgres
database.password=YOUR_DATABASE_PASSWORD

# JWT secret for authentication
jwt.secret=YOUR_JWT_SECRET

# Instana agent key for backend APM tracing
instana.agent.key=YOUR_INSTANA_AGENT_KEY
```

**Where to get values:**
- `database.password`: Choose a strong password
- `jwt.secret`: Generate with `openssl rand -base64 32`
- `instana.agent.key`: Instana UI → Settings → Agent Keys

### Frontend Secrets (`frontend-secrets.env`)

Contains frontend monitoring configuration:

```bash
# Instana End User Monitoring (EUM) key
instana.eum.key=YOUR_INSTANA_EUM_KEY
```

**Where to get values:**
- `instana.eum.key`: Instana UI → Settings → Websites & Mobile Apps

## How It Works

### Kustomize SecretGenerator

The `gitops/overlays/dev/kustomization.yaml` file uses Kustomize's `secretGenerator`:

```yaml
secretGenerator:
  - name: backend-secret
    envs:
      - secrets.env
    options:
      disableNameSuffixHash: true
  - name: frontend-config
    envs:
      - frontend-secrets.env
    options:
      disableNameSuffixHash: true
    behavior: merge
```

When you run `kubectl apply -k gitops/overlays/dev`, Kustomize:
1. Reads the `.env` files
2. Generates Kubernetes Secret resources
3. Applies them to the cluster

### Git Ignore

The `.gitignore` file ensures secrets are never committed:

```gitignore
# Secret files - DO NOT commit these
gitops/overlays/*/secrets.env
gitops/overlays/*/frontend-secrets.env
```

## Deployment

### Using kubectl

```bash
# Deploy with secrets
kubectl apply -k gitops/overlays/dev
```

### Using ArgoCD

When using ArgoCD, you have two options:

#### Option 1: Manual Secret Creation

Create secrets manually before syncing:

```bash
# Create backend secret
kubectl create secret generic backend-secret \
  --from-env-file=gitops/overlays/dev/secrets.env \
  -n ecommerce-dev

# Create frontend config (merge with existing)
kubectl create configmap frontend-config \
  --from-env-file=gitops/overlays/dev/frontend-secrets.env \
  -n ecommerce-dev \
  --dry-run=client -o yaml | kubectl apply -f -
```

Then sync ArgoCD:

```bash
argocd app sync ecommerce-dev
```

#### Option 2: ArgoCD Vault Plugin

For production environments, consider using [ArgoCD Vault Plugin](https://argocd-vault-plugin.readthedocs.io/) to integrate with:
- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager

## Security Best Practices

### 1. Never Commit Secrets

Always verify secrets are gitignored:

```bash
git status
# Should NOT show secrets.env or frontend-secrets.env
```

### 2. Use Strong Passwords

Generate secure passwords:

```bash
# Database password
openssl rand -base64 32

# JWT secret
openssl rand -base64 32
```

### 3. Rotate Credentials Regularly

Update secrets periodically:

```bash
# Edit the secret files
nano gitops/overlays/dev/secrets.env

# Reapply
kubectl apply -k gitops/overlays/dev

# Restart pods to pick up new secrets
kubectl rollout restart deployment/backend -n ecommerce-dev
```

### 4. Use Different Secrets Per Environment

Each environment should have unique secrets:

```
gitops/overlays/
├── dev/
│   ├── secrets.env          # Dev secrets
│   └── frontend-secrets.env
├── staging/
│   ├── secrets.env          # Staging secrets
│   └── frontend-secrets.env
└── prod/
    ├── secrets.env          # Production secrets
    └── frontend-secrets.env
```

### 5. Limit Access

Restrict who can view secrets:

```bash
# Use Kubernetes RBAC
kubectl create role secret-reader \
  --verb=get,list \
  --resource=secrets \
  -n ecommerce-dev

# Grant to specific users only
kubectl create rolebinding secret-reader-binding \
  --role=secret-reader \
  --user=admin@example.com \
  -n ecommerce-dev
```

## Troubleshooting

### Secrets Not Found

If pods fail with "secret not found":

```bash
# Check if secrets exist
kubectl get secrets -n ecommerce-dev

# Verify secret content (be careful - this shows secrets!)
kubectl get secret backend-secret -n ecommerce-dev -o yaml

# Recreate secrets
kubectl apply -k gitops/overlays/dev
```

### Wrong Secret Values

If the application uses wrong values:

```bash
# Update the .env files
nano gitops/overlays/dev/secrets.env

# Delete old secret
kubectl delete secret backend-secret -n ecommerce-dev

# Recreate
kubectl apply -k gitops/overlays/dev

# Restart pods
kubectl rollout restart deployment/backend -n ecommerce-dev
```

### ArgoCD Not Picking Up Secrets

ArgoCD doesn't automatically sync secrets from `.env` files. You need to:

1. Create secrets manually first, OR
2. Use ArgoCD Vault Plugin, OR
3. Use a pre-sync hook to create secrets

## Migration from Hardcoded Secrets

If you're migrating from hardcoded secrets:

1. **Backup existing secrets:**
   ```bash
   kubectl get secret backend-secret -n ecommerce-dev -o yaml > backup-secret.yaml
   ```

2. **Create `.env` files with current values:**
   ```bash
   cd gitops/overlays/dev
   cp secrets.env.example secrets.env
   # Edit with current values from backup
   ```

3. **Update kustomization.yaml** (already done in this repo)

4. **Test in dev environment first**

5. **Deploy to production after verification**

## Additional Resources

- [Kustomize Secret Generator](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/secretgenerator/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [ArgoCD Vault Plugin](https://argocd-vault-plugin.readthedocs.io/)
- [Instana Setup Guide](INSTANA-SETUP.md)

## Support

For issues with secrets management:
1. Check this guide
2. Review [INSTANA-SETUP.md](INSTANA-SETUP.md)
3. Check [QUICKSTART.md](../QUICKSTART.md)
4. Open an issue on GitHub

---

**Made with Bob**