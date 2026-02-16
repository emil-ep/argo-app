# Docker Hub Rate Limit Solution

## Problem

Docker Hub limits unauthenticated image pulls to 100 pulls per 6 hours per IP address. This causes errors like:

```
429 Too Many Requests - You have reached your unauthenticated pull rate limit
```

## Solutions

### Option 1: Use Docker Hub Credentials (Recommended)

Create a Docker Hub account and use authenticated pulls to get 200 pulls per 6 hours.

#### Step 1: Create Docker Hub Account

1. Go to https://hub.docker.com/signup
2. Create a free account
3. Verify your email

#### Step 2: Create Kubernetes Secret

```bash
# Create docker-registry secret in the namespace
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=YOUR_DOCKERHUB_USERNAME \
  --docker-password=YOUR_DOCKERHUB_PASSWORD \
  --docker-email=YOUR_EMAIL \
  -n ecommerce-dev
```

#### Step 3: Update StatefulSet

Add the secret to `gitops/base/database/statefulset.yaml`:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  template:
    spec:
      imagePullSecrets:
        - name: dockerhub-secret  # Add this
      containers:
        - name: postgres
          image: postgres:15-alpine
          # ... rest of config
```

#### Step 4: Apply Changes

```bash
# If using ArgoCD
argocd app sync ecommerce-dev

# Or manually
kubectl apply -k gitops/overlays/dev/
```

### Option 2: Use Alternative Registry

Use GitHub Container Registry mirror or other alternatives.

#### Create PostgreSQL Image in GHCR

1. **Create Dockerfile for PostgreSQL**:

```dockerfile
# postgres.Dockerfile
FROM postgres:15-alpine
```

2. **Build and push to GHCR**:

```bash
docker build -f postgres.Dockerfile -t ghcr.io/YOUR_USERNAME/postgres:15-alpine .
docker push ghcr.io/YOUR_USERNAME/postgres:15-alpine
```

3. **Update StatefulSet**:

```yaml
containers:
  - name: postgres
    image: ghcr.io/YOUR_USERNAME/postgres:15-alpine
```

### Option 3: Use Minikube/Kind with Local Images

If using local Kubernetes (minikube/kind), pull images once:

```bash
# For minikube
minikube ssh docker pull postgres:15-alpine

# For kind
docker pull postgres:15-alpine
kind load docker-image postgres:15-alpine
```

### Option 4: Wait and Retry

Docker Hub rate limits reset after 6 hours. You can wait and try again.

## Recommended Approach

**For Production**: Use Option 1 (Docker Hub credentials) or host your own PostgreSQL image in GHCR.

**For Development**: Use Option 3 (local images) or Option 1.

## Checking Rate Limit Status

```bash
# Check your current rate limit
TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
curl --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest
```

Look for headers:
- `ratelimit-limit`: Your total limit
- `ratelimit-remaining`: Remaining pulls

## Automated Solution

Add this to your cluster setup script:

```bash
#!/bin/bash
# setup-dockerhub-auth.sh

NAMESPACE="ecommerce-dev"
DOCKERHUB_USERNAME="your-username"
DOCKERHUB_PASSWORD="your-password"
DOCKERHUB_EMAIL="your-email"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create docker-registry secret
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=$DOCKERHUB_USERNAME \
  --docker-password=$DOCKERHUB_PASSWORD \
  --docker-email=$DOCKERHUB_EMAIL \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Docker Hub authentication configured for namespace: $NAMESPACE"
```

## Prevention

To avoid this issue in the future:

1. ✅ Always use authenticated pulls for public images
2. ✅ Host critical images in your own registry (GHCR)
3. ✅ Use image pull secrets in all deployments
4. ✅ Consider using a registry mirror/cache
5. ✅ Monitor your rate limit usage

## Additional Resources

- [Docker Hub Rate Limits](https://docs.docker.com/docker-hub/download-rate-limit/)
- [Kubernetes Image Pull Secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)