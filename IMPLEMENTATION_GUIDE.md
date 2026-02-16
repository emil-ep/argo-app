# Implementation Guide - E-Commerce Application

## Quick Reference

### Project Overview
- **Frontend**: React + Vite + Nginx
- **Backend**: Node.js + Express + Sequelize/Prisma
- **Database**: PostgreSQL 15
- **Deployment**: Kubernetes + ArgoCD + Kustomize

## Directory Structure Summary

```
argo-app/
├── frontend/          # React application
├── backend/           # Express API
├── gitops/            # Kubernetes manifests
│   ├── base/          # Base configurations
│   ├── overlays/      # Environment-specific configs
│   └── argocd/        # ArgoCD Application definitions
└── docs/              # Documentation
```

## Key Features

### E-Commerce Functionality
✅ Product catalog with categories
✅ Shopping cart management
✅ User authentication (JWT)
✅ Order processing
✅ Admin product management

### DevOps Features
✅ Containerized applications (Docker)
✅ Kubernetes-native deployment
✅ ArgoCD GitOps workflow
✅ Environment-based configuration (dev/staging/prod)
✅ No hardcoded values - all configurable
✅ Health checks and readiness probes
✅ Horizontal pod autoscaling ready

## Configuration Strategy

### Environment Variables Flow
```
ConfigMap (non-sensitive) → Pod Environment
Secret (sensitive) → Pod Environment
Application reads from process.env
```

### Frontend Configuration
- API URL injected via Nginx at runtime
- No rebuild needed for different environments
- Uses window.ENV object for runtime config

### Backend Configuration
- Database connection from environment variables
- JWT secret from Kubernetes Secret
- Port and other settings from ConfigMap

## Deployment Workflow

1. **Build Docker Images**
   ```bash
   docker build -t your-registry/ecommerce-frontend:v1.0.0 ./frontend
   docker build -t your-registry/ecommerce-backend:v1.0.0 ./backend
   docker push your-registry/ecommerce-frontend:v1.0.0
   docker push your-registry/ecommerce-backend:v1.0.0
   ```

2. **Update GitOps Repository**
   - Update image tags in gitops/overlays/{env}/kustomization.yaml
   - Commit and push changes

3. **ArgoCD Syncs Automatically**
   - Detects Git changes
   - Applies to Kubernetes cluster
   - Self-heals if manual changes occur

## Access Pattern

```
User Browser
    ↓
Ingress (your-domain.com)
    ↓
Frontend Service → Frontend Pods (Nginx + React)
    ↓ (API calls to /api/*)
Backend Service → Backend Pods (Express)
    ↓
Database Service → PostgreSQL StatefulSet
```

## Key Configuration Files

### ArgoCD Applications
- `gitops/argocd/database-app.yaml` - PostgreSQL deployment
- `gitops/argocd/backend-app.yaml` - Backend API deployment
- `gitops/argocd/frontend-app.yaml` - Frontend deployment

### Kustomize Structure
- `gitops/base/` - Common configurations
- `gitops/overlays/dev/` - Development settings
- `gitops/overlays/staging/` - Staging settings
- `gitops/overlays/prod/` - Production settings

## Environment-Specific Differences

| Aspect | Dev | Staging | Prod |
|--------|-----|---------|------|
| Replicas | 1 | 2 | 3+ |
| Resources | Minimal | Medium | High |
| Domain | dev.example.com | staging.example.com | example.com |
| Debug Mode | Enabled | Enabled | Disabled |
| Auto-sync | Yes | Yes | Manual approval |

## Security Checklist

- [ ] Database credentials in Kubernetes Secret
- [ ] JWT secret in Kubernetes Secret
- [ ] CORS properly configured
- [ ] HTTPS/TLS enabled (cert-manager)
- [ ] Network policies defined
- [ ] RBAC configured for ArgoCD
- [ ] Container images scanned
- [ ] No secrets in Git repository

## Testing Strategy

### Local Development
```bash
# Frontend
cd frontend && npm install && npm run dev

# Backend
cd backend && npm install && npm run dev

# Database
docker run -p 5432:5432 -e POSTGRES_PASSWORD=password postgres:15
```

### Kubernetes Testing
```bash
# Apply to local cluster (minikube/kind)
kubectl apply -k gitops/overlays/dev

# Port forward for testing
kubectl port-forward svc/frontend 8080:80
kubectl port-forward svc/backend 3000:3000
```

## Monitoring Points

### Application Metrics
- Request rate and latency
- Error rates
- Database connection pool status
- Cart conversion rate
- Order processing time

### Infrastructure Metrics
- Pod CPU/Memory usage
- Pod restart count
- Database storage usage
- Ingress request rate

## Troubleshooting

### Common Issues

**Pods not starting**
- Check image pull secrets
- Verify image tags exist
- Review pod logs: `kubectl logs <pod-name>`

**Database connection failed**
- Verify Secret exists and is correct
- Check Service DNS resolution
- Ensure database is ready before backend starts

**Frontend can't reach backend**
- Verify API_URL in ConfigMap
- Check Ingress configuration
- Review CORS settings in backend

**ArgoCD not syncing**
- Check Application health status
- Verify Git repository access
- Review sync policy settings

## Next Steps After Implementation

1. Set up CI/CD pipeline for automated builds
2. Configure monitoring (Prometheus/Grafana)
3. Set up logging aggregation (EFK stack)
4. Implement backup strategy for database
5. Configure SSL certificates (cert-manager)
6. Set up alerting rules
7. Create runbooks for operations team
8. Performance testing and optimization

## Prerequisites for Deployment

### Required Tools
- Docker
- kubectl
- ArgoCD CLI (optional)
- Kustomize (built into kubectl)

### Kubernetes Cluster Requirements
- Kubernetes 1.24+
- Ingress controller installed (nginx-ingress)
- StorageClass for PersistentVolumes
- ArgoCD installed in cluster

### Container Registry
- Docker Hub, GitHub Container Registry, or private registry
- Credentials configured in Kubernetes

## Estimated Implementation Time

- Backend API: 4-6 hours
- Frontend Application: 4-6 hours
- Kubernetes Manifests: 2-3 hours
- ArgoCD Configuration: 1-2 hours
- Testing & Documentation: 2-3 hours

**Total: 13-20 hours**

## Support & Resources

- Kubernetes Documentation: https://kubernetes.io/docs/
- ArgoCD Documentation: https://argo-cd.readthedocs.io/
- React Documentation: https://react.dev/
- Express Documentation: https://expressjs.com/
- PostgreSQL Documentation: https://www.postgresql.org/docs/