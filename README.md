# E-Commerce Application - ArgoCD Ready

A complete e-commerce application built with React, Node.js/Express, and PostgreSQL, designed for deployment with ArgoCD and Kubernetes.

## 🏗️ Architecture

- **Frontend**: React 18 + Vite + Material-UI + Nginx
- **Backend**: Node.js 20 + Express + Sequelize
- **Database**: PostgreSQL 15
- **Deployment**: Kubernetes + ArgoCD + Kustomize

## 📁 Project Structure

```
argo-app/
├── frontend/           # React application
├── backend/            # Express API
├── gitops/             # Kubernetes manifests
│   ├── base/           # Base configurations
│   ├── overlays/       # Environment-specific configs
│   └── argocd/         # ArgoCD applications
├── docs/               # Documentation
├── ARCHITECTURE.md     # Detailed architecture
└── README.md           # This file
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- ArgoCD installed in cluster
- Container registry access

### Local Development

#### Backend

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your database credentials
npm run dev
```

#### Frontend

```bash
cd frontend
npm install
npm run dev
```

#### Database

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_DB=ecommerce \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15-alpine
```

#### Seed Database

```bash
cd backend
npm run seed
```

**Test Credentials:**
- Admin: `admin@example.com` / `admin123`
- User: `user@example.com` / `user123`

## 🤖 CI/CD Pipeline

This project includes an automated CI/CD pipeline using GitHub Actions for building and publishing container images.

### How It Works

**Automatic (CI):**
- ✅ Builds Docker images when `backend/` or `frontend/` changes
- ✅ Pushes images to GitHub Container Registry (GHCR)
- ✅ Tags with semantic versions (v1.0.X)
- ✅ Creates GitHub releases

**Manual (CD):**
- 📝 You manually update `gitops/overlays/dev/kustomization.yaml` with desired version
- 🔄 ArgoCD automatically syncs changes to Kubernetes

### Quick Setup

1. **Generate package-lock.json files**:
   ```bash
   cd backend && npm install --package-lock-only && cd ..
   cd frontend && npm install --package-lock-only && cd ..
   ```

2. **Update image references** in `gitops/overlays/dev/kustomization.yaml`:
   ```yaml
   images:
     - name: ecommerce-backend
       newName: ghcr.io/YOUR_USERNAME/argo-app/backend  # ← Change this
       newTag: latest
     - name: ecommerce-frontend
       newName: ghcr.io/YOUR_USERNAME/argo-app/frontend  # ← Change this
       newTag: latest
   ```

3. **Update repository URL** in `gitops/argocd/application.yaml`:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/YOUR_USERNAME/argo-app.git  # ← Change this
   ```

4. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Initial setup"
   git push origin main
   ```

5. **Deploy manually** - See [Manual Deployment Guide](docs/MANUAL-DEPLOYMENT.md)

4. **ArgoCD syncs automatically** - Your app deploys within minutes!

### What Happens on Push to Main

```
Code Push → Build Images → Push to GHCR → Update GitOps → ArgoCD Syncs → Deployed! 🚀
```

**See [CI/CD Setup Guide](docs/CI-CD-SETUP.md) for detailed instructions.**

## 🐳 Manual Docker Build (Optional)

If you prefer manual builds:

### Build Images

```bash
# Backend
docker build -t ghcr.io/YOUR_USERNAME/argo-app/backend:v1.0.0 ./backend

# Frontend
docker build -t ghcr.io/YOUR_USERNAME/argo-app/frontend:v1.0.0 ./frontend
```

### Push to Registry

```bash
docker push ghcr.io/YOUR_USERNAME/argo-app/backend:v1.0.0
docker push ghcr.io/YOUR_USERNAME/argo-app/frontend:v1.0.0
```

## ☸️ Kubernetes Deployment

### 1. Update Image References

Edit `gitops/overlays/dev/kustomization.yaml`:

```yaml
images:
  - name: ecommerce-backend
    newName: your-registry/ecommerce-backend
    newTag: v1.0.0
  - name: ecommerce-frontend
    newName: your-registry/ecommerce-frontend
    newTag: v1.0.0
```

### 2. Update Secrets

**IMPORTANT**: Change default passwords before deploying to production!

```bash
# Generate strong passwords
kubectl create secret generic postgres-secret \
  --from-literal=username=postgres \
  --from-literal=password=$(openssl rand -base64 32) \
  -n ecommerce-dev --dry-run=client -o yaml > gitops/overlays/dev/postgres-secret.yaml

kubectl create secret generic backend-secret \
  --from-literal=jwt.secret=$(openssl rand -base64 64) \
  -n ecommerce-dev --dry-run=client -o yaml > gitops/overlays/dev/backend-secret.yaml
```

### 3. Deploy with kubectl (Manual)

```bash
# Apply all resources
kubectl apply -k gitops/overlays/dev

# Check deployment status
kubectl get pods -n ecommerce-dev
kubectl get svc -n ecommerce-dev
kubectl get ingress -n ecommerce-dev
```

### 4. Deploy with ArgoCD (GitOps)

#### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### Access ArgoCD UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

#### Create Application

Update `gitops/argocd/application.yaml` with your Git repository URL, then:

```bash
kubectl apply -f gitops/argocd/application.yaml
```

Or via ArgoCD CLI:

```bash
argocd app create ecommerce-dev \
  --repo https://github.com/your-org/argo-app.git \
  --path gitops/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ecommerce-dev \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

## 🌐 Access the Application

### Local Development

- Frontend: http://localhost:5173
- Backend API: http://localhost:3000
- API Docs: http://localhost:3000/

### Kubernetes (with Ingress)

Add to `/etc/hosts`:
```
127.0.0.1 ecommerce-dev.local
```

Access: http://ecommerce-dev.local

### Port Forward (without Ingress)

```bash
# Frontend
kubectl port-forward svc/frontend 8080:80 -n ecommerce-dev

# Backend
kubectl port-forward svc/backend 3000:3000 -n ecommerce-dev
```

## 📊 Monitoring

### Check Application Health

```bash
# Backend health
curl http://backend-service:3000/health/live
curl http://backend-service:3000/health/ready

# Frontend health
curl http://frontend-service/health
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

### ArgoCD Sync Status

```bash
argocd app get ecommerce-dev
argocd app sync ecommerce-dev
argocd app history ecommerce-dev
```

## 🔧 Configuration

### Environment Variables

All configuration is managed through Kubernetes ConfigMaps and Secrets:

- **Database**: `gitops/base/database/configmap.yaml` & `secret.yaml`
- **Backend**: `gitops/base/backend/configmap.yaml` & `secret.yaml`
- **Frontend**: `gitops/base/frontend/configmap.yaml`

### Scaling

```bash
# Scale backend
kubectl scale deployment backend --replicas=3 -n ecommerce-dev

# Scale frontend
kubectl scale deployment frontend --replicas=3 -n ecommerce-dev
```

## 🔐 Security Considerations

1. **Change default passwords** in production
2. **Use proper secrets management** (Sealed Secrets, External Secrets Operator)
3. **Enable TLS/HTTPS** with cert-manager
4. **Implement network policies**
5. **Regular security scans** of container images
6. **RBAC** for ArgoCD and Kubernetes access

## 🐛 Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n ecommerce-dev
kubectl logs <pod-name> -n ecommerce-dev
```

### Database connection issues

```bash
# Test database connectivity
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -n ecommerce-dev -- \
  psql -h postgres -U postgres -d ecommerce
```

### ArgoCD sync issues

```bash
# Check application status
argocd app get ecommerce-dev

# Force sync
argocd app sync ecommerce-dev --force

# View sync history
argocd app history ecommerce-dev
```

## 📚 API Documentation

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Get current user

### Products

- `GET /api/products` - List products
- `GET /api/products/:id` - Get product details
- `POST /api/products` - Create product (admin)

### Cart

- `GET /api/cart` - Get cart
- `POST /api/cart/items` - Add to cart
- `PUT /api/cart/items/:id` - Update quantity
- `DELETE /api/cart/items/:id` - Remove item

### Orders

- `GET /api/orders` - Get user orders
- `POST /api/orders` - Create order
- `GET /api/orders/:id` - Get order details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 📞 Support

For issues and questions:
- GitHub Issues: https://github.com/your-org/argo-app/issues
- Documentation: See `docs/` directory

## 🎯 Roadmap

- [ ] Add payment integration
- [ ] Implement product reviews
- [ ] Add admin dashboard
- [ ] Set up CI/CD pipeline
- [ ] Add monitoring with Prometheus/Grafana
- [ ] Implement caching with Redis
- [ ] Add search functionality with Elasticsearch