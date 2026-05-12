# Installation & Uninstallation Guide

## Installation

```bash
# 1. Clone repository
git clone https://github.com/emil-ep/argo-app.git
cd argo-app

# 2. Configure secrets (Instana keys, Docker Hub auth, etc.)
./scripts/setup-secrets.sh

# 3. Deploy application
kubectl apply -k gitops/overlays/dev

# 4. Access application
# Frontend: http://<NODE_IP>:30080
# Backend:  http://<NODE_IP>:30300
```

## Uninstallation

```bash
# Delete all resources
kubectl delete -k gitops/overlays/dev

# Or delete namespace (removes everything)
kubectl delete namespace ecommerce-dev
```

---

**For detailed documentation, see:**
- [QUICKSTART.md](QUICKSTART.md) - Full quick start guide
- [docs/INSTANA-SETUP.md](docs/INSTANA-SETUP.md) - Instana configuration
- [docs/SECRETS-MANAGEMENT.md](docs/SECRETS-MANAGEMENT.md) - Security guide