# Installation & Uninstallation Guide

## Quick Installation (Recommended)

The application can be installed with a single command:

```bash
./install.sh
```

This automated script will:
1. ✅ Check prerequisites (kubectl, Kubernetes cluster)
2. ✅ Guide you through secrets configuration (Instana keys, database password, JWT secret)
3. ✅ Create Kubernetes secrets and ConfigMaps
4. ✅ Deploy the application (via ArgoCD or kubectl)
5. ✅ Wait for all pods to be ready
6. ✅ Display access URLs and useful commands

### Prerequisites

- **kubectl** installed and configured
- **Kubernetes cluster** accessible
- **ArgoCD** (optional, for GitOps deployment)
- **Instana credentials** (Agent Key and EUM Key)

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/emil-ep/argo-app.git
   cd argo-app
   ```

2. **Run the installation script:**
   ```bash
   ./install.sh
   ```

3. **Follow the prompts:**
   - Choose deployment method (ArgoCD or kubectl)
   - Enter Instana Agent Key and EUM Key
   - Configure database password (or use default)
   - Optionally configure Docker Hub authentication

4. **Access the application:**
   - The script will display access URLs at the end
   - Add the ingress hostname to `/etc/hosts` if using Ingress

### Deployment Methods

The installer supports two deployment methods:

#### 1. ArgoCD (GitOps - Recommended)
- Automatic sync and self-healing
- Declarative configuration
- Full GitOps workflow
- Requires ArgoCD to be installed

#### 2. Direct kubectl
- Simple and fast
- No additional tools required
- Manual updates needed

---

## Quick Uninstallation

Remove the application with a single command:

```bash
./uninstall.sh
```

This will:
- ✅ Remove all application resources
- ✅ Delete the namespace
- ✅ Remove ArgoCD application (if exists)
- ✅ Clean up all pods, services, and deployments

**Note:** Secret files (`secrets.env`, `frontend-secrets.env`) are preserved and must be deleted manually if needed.

---

## Manual Installation (Advanced)

If you prefer manual installation or need more control:

### 1. Configure Secrets

```bash
./scripts/setup-secrets.sh
```

This creates:
- `gitops/overlays/dev/secrets.env` - Backend secrets
- `gitops/overlays/dev/frontend-secrets.env` - Frontend secrets

### 2. Create Kubernetes Secrets

```bash
# Create namespace
kubectl create namespace ecommerce-dev

# Create backend secret
kubectl create secret generic backend-secret \
  --from-env-file=gitops/overlays/dev/secrets.env \
  -n ecommerce-dev

# Create frontend configmap
kubectl create configmap frontend-config \
  --from-env-file=gitops/overlays/dev/frontend-secrets.env \
  -n ecommerce-dev
```

### 3. Deploy Application

**Option A: Using ArgoCD**
```bash
kubectl apply -f gitops/argocd/application.yaml
```

**Option B: Using kubectl**
```bash
kubectl apply -k gitops/overlays/dev
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n ecommerce-dev

# Check ArgoCD application (if using ArgoCD)
kubectl get application ecommerce-dev -n argocd
```

---

## Access Information

### Via Ingress (if configured)
- **Frontend:** http://ecommerce-dev.local/
- **Backend API:** http://ecommerce-dev.local/api

Add to `/etc/hosts`:
```bash
echo "<NODE_IP> ecommerce-dev.local" | sudo tee -a /etc/hosts
```

### Via NodePort
- **Frontend:** http://\<NODE_IP\>:\<FRONTEND_NODEPORT\>
- **Backend:** http://\<NODE_IP\>:\<BACKEND_NODEPORT\>

Get NodePort values:
```bash
kubectl get svc -n ecommerce-dev
```

---

## Updating Secrets

To update secrets after installation:

```bash
# Update backend secrets
kubectl create secret generic backend-secret \
  --from-env-file=gitops/overlays/dev/secrets.env \
  -n ecommerce-dev \
  --dry-run=client -o yaml | kubectl apply -f -

# Update frontend config
kubectl create configmap frontend-config \
  --from-env-file=gitops/overlays/dev/frontend-secrets.env \
  -n ecommerce-dev \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up changes
kubectl rollout restart deployment frontend -n ecommerce-dev
kubectl rollout restart rollout backend -n ecommerce-dev
```

---

## Troubleshooting

### Pods not starting
```bash
# Check pod status
kubectl get pods -n ecommerce-dev

# View pod logs
kubectl logs <pod-name> -n ecommerce-dev

# Describe pod for events
kubectl describe pod <pod-name> -n ecommerce-dev
```

### ArgoCD sync issues
```bash
# Check application status
kubectl describe application ecommerce-dev -n argocd

# Manually trigger sync
kubectl patch application ecommerce-dev -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

### Database connection issues
```bash
# Check database pod
kubectl logs postgres-0 -n ecommerce-dev

# Verify secrets
kubectl get secret backend-secret -n ecommerce-dev -o yaml
```

---

## Additional Resources

- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
- **[docs/INSTANA-SETUP.md](docs/INSTANA-SETUP.md)** - Instana configuration
- **[docs/SECRETS-MANAGEMENT.md](docs/SECRETS-MANAGEMENT.md)** - Security guide
- **[docs/CI-CD-SETUP.md](docs/CI-CD-SETUP.md)** - CI/CD pipeline setup

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the documentation in the `docs/` directory
3. Open an issue on GitHub

---

**Made with Bob**
