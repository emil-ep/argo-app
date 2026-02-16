# 🚀 Quick Start Guide

Get your e-commerce application running with automated CI/CD in minutes!

## Prerequisites

- GitHub account
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl installed and configured
- ArgoCD installed in your cluster

## Step 1: Fork/Clone Repository

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/argo-app.git
cd argo-app
```

## Step 2: Update Configuration

Edit `gitops/overlays/dev/kustomization.yaml`:

```yaml
images:
  - name: ecommerce-backend
    newName: ghcr.io/YOUR_GITHUB_USERNAME/argo-app/backend  # ← Change this
    newTag: latest
  - name: ecommerce-frontend
    newName: ghcr.io/YOUR_GITHUB_USERNAME/argo-app/frontend  # ← Change this
    newTag: latest
```

Edit `gitops/argocd/application.yaml`:

```yaml
spec:
  source:
    repoURL: https://github.com/YOUR_USERNAME/argo-app.git  # ← Change this
```

## Step 3: Push to GitHub

```bash
git add .
git commit -m "Initial commit with CI/CD setup"
git push origin main
```

**🎉 GitHub Actions will automatically:**
- Build your Docker images
- Push to GitHub Container Registry
- Version with semantic tags (v1.0.1, v1.0.2, etc.)
- Update GitOps manifests
- Create a GitHub release

## Step 4: Install ArgoCD (if not already installed)

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

## Step 5: Access ArgoCD UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"
```

Open browser: https://localhost:8080
- Username: `admin`
- Password: (from above command)

## Step 6: Deploy Application with ArgoCD

```bash
# Apply ArgoCD application
kubectl apply -f gitops/argocd/application.yaml

# Or via ArgoCD CLI
argocd app create ecommerce-dev \
  --repo https://github.com/YOUR_USERNAME/argo-app.git \
  --path gitops/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ecommerce-dev \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

## Step 7: Wait for Deployment

```bash
# Watch ArgoCD sync
argocd app get ecommerce-dev --watch

# Or watch pods
kubectl get pods -n ecommerce-dev -w
```

## Step 8: Access Your Application

### Option A: Using Ingress

Add to `/etc/hosts`:
```
127.0.0.1 ecommerce-dev.local
```

Access: http://ecommerce-dev.local

### Option B: Port Forward

```bash
# Frontend
kubectl port-forward svc/frontend 8080:80 -n ecommerce-dev

# Backend
kubectl port-forward svc/backend 3000:3000 -n ecommerce-dev
```

Access: http://localhost:8080

## 🎯 Test the Application

1. **Browse Products**: Visit the homepage
2. **Register**: Create a new account
3. **Add to Cart**: Add some products
4. **Checkout**: Place an order
5. **View Orders**: Check your order history

### Test Credentials (from seed data)

- **Admin**: `admin@example.com` / `admin123`
- **User**: `user@example.com` / `user123`

## 🔄 Test CI/CD Pipeline

Make a change and push:

```bash
# Edit a file
echo "// Test change" >> backend/src/server.js

# Commit and push
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

**Watch the magic happen:**

1. **GitHub Actions** (https://github.com/YOUR_USERNAME/argo-app/actions)
   - Builds new images
   - Pushes to GHCR
   - Updates GitOps manifests
   - Creates release

2. **ArgoCD** (https://localhost:8080)
   - Detects changes (within 3 minutes)
   - Syncs new version
   - Updates pods with zero downtime

3. **Kubernetes**
   ```bash
   kubectl get pods -n ecommerce-dev -w
   ```
   - Watch rolling update

## 📊 Monitoring

### Check Application Health

```bash
# Backend health
kubectl port-forward svc/backend 3000:3000 -n ecommerce-dev
curl http://localhost:3000/health/ready

# Frontend health
kubectl port-forward svc/frontend 8080:80 -n ecommerce-dev
curl http://localhost:8080/health
```

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n ecommerce-dev

# Frontend logs
kubectl logs -f deployment/frontend -n ecommerce-dev

# Database logs
kubectl logs -f statefulset/postgres -n ecommerce-dev
```

### ArgoCD Status

```bash
# Application status
argocd app get ecommerce-dev

# Sync history
argocd app history ecommerce-dev

# Recent events
kubectl get events -n ecommerce-dev --sort-by='.lastTimestamp'
```

## 🐛 Troubleshooting

### Images Not Pulling

If you see `ImagePullBackOff`:

```bash
# Make images public in GitHub
# Go to: https://github.com/YOUR_USERNAME?tab=packages
# Click on package → Settings → Change visibility → Public

# Or create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  -n ecommerce-dev
```

### ArgoCD Not Syncing

```bash
# Force refresh
argocd app refresh ecommerce-dev

# Force sync
argocd app sync ecommerce-dev --force

# Check application details
argocd app get ecommerce-dev
```

### Database Connection Issues

```bash
# Check database pod
kubectl get pods -n ecommerce-dev | grep postgres

# Check database logs
kubectl logs statefulset/postgres -n ecommerce-dev

# Test connection
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -n ecommerce-dev -- \
  psql -h postgres -U postgres -d ecommerce
```

## 🎓 Next Steps

1. **Customize the Application**
   - Add new features
   - Modify UI/UX
   - Add more products

2. **Set Up Monitoring**
   - Install Prometheus & Grafana
   - Configure alerts
   - Set up logging (EFK stack)

3. **Production Deployment**
   - Create production overlay
   - Set up staging environment
   - Configure SSL/TLS certificates
   - Implement backup strategy

4. **Security Hardening**
   - Change default passwords
   - Set up network policies
   - Enable pod security policies
   - Scan images for vulnerabilities

## 📚 Documentation

- [Full README](README.md)
- [Architecture Guide](ARCHITECTURE.md)
- [CI/CD Setup](docs/CI-CD-SETUP.md)
- [Implementation Guide](IMPLEMENTATION_GUIDE.md)

## 🆘 Need Help?

- Check [Troubleshooting Guide](docs/CI-CD-SETUP.md#-troubleshooting)
- Review [GitHub Actions logs](https://github.com/YOUR_USERNAME/argo-app/actions)
- Check [ArgoCD documentation](https://argo-cd.readthedocs.io/)
- Open an issue on GitHub

## ✅ Success Checklist

- [ ] Repository pushed to GitHub
- [ ] GitHub Actions workflow completed successfully
- [ ] Docker images visible in GitHub Packages
- [ ] ArgoCD installed and accessible
- [ ] Application deployed to Kubernetes
- [ ] Can access the application UI
- [ ] Can register and login
- [ ] Can add products to cart
- [ ] Can place orders
- [ ] CI/CD pipeline tested with a code change

**Congratulations! 🎉 Your e-commerce application is now running with automated CI/CD!**