# Canary Deployment with Argo Rollouts

This guide explains how to implement canary deployments for your e-commerce application using Argo Rollouts.

## 📋 Table of Contents

- [What is Canary Deployment?](#what-is-canary-deployment)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Monitoring](#monitoring)
- [Rollback](#rollback)
- [Advanced Features](#advanced-features)

## 🎯 What is Canary Deployment?

Canary deployment is a progressive delivery strategy that:
- Deploys new version to a small subset of users first
- Gradually increases traffic to the new version
- Monitors metrics to ensure stability
- Automatically rolls back if issues are detected
- Minimizes risk of bad deployments

### Our Canary Strategy

```
Step 1: 20% traffic → Wait 2 minutes
Step 2: 40% traffic → Wait 2 minutes
Step 3: 60% traffic → Wait 2 minutes
Step 4: 80% traffic → Wait 2 minutes
Step 5: 100% traffic (full rollout)
```

## 📋 Prerequisites

- Kubernetes cluster
- ArgoCD installed
- NGINX Ingress Controller
- kubectl installed
- (Optional) Prometheus for automated analysis

## 🚀 Installation

### Step 1: Install Argo Rollouts Controller

```bash
# Create namespace
kubectl create namespace argo-rollouts

# Install Argo Rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Verify installation
kubectl get pods -n argo-rollouts

# Expected output:
# NAME                             READY   STATUS    RESTARTS   AGE
# argo-rollouts-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

### Step 2: Install kubectl Plugin (Optional but Recommended)

```bash
# For macOS
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-darwin-amd64
chmod +x kubectl-argo-rollouts-darwin-amd64
sudo mv kubectl-argo-rollouts-darwin-amd64 /usr/local/bin/kubectl-argo-rollouts

# For Linux
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Verify
kubectl argo rollouts version
```

### Step 3: Install Argo Rollouts Dashboard (Optional)

```bash
# Install dashboard
kubectl apply -f https://github.com/argoproj/argo-rollouts/releases/latest/download/dashboard-install.yaml

# Port forward to access
kubectl port-forward -n argo-rollouts svc/argo-rollouts-dashboard 3100:3100

# Access at: http://localhost:3100
```

## ⚙️ Configuration

### Step 1: Switch to Rollout Configuration

```bash
# Backup current kustomization
cd gitops/base/backend
cp kustomization.yaml kustomization-deployment.yaml.bak

# Use rollout configuration
cp kustomization-rollout.yaml kustomization.yaml

# Commit changes
git add kustomization.yaml
git commit -m "feat: enable canary deployments with Argo Rollouts"
git push origin main
```

### Step 2: Delete Existing Deployment

```bash
# Delete the old deployment (Rollout will replace it)
kubectl delete deployment backend -n ecommerce-dev

# ArgoCD will sync and create the Rollout
argocd app sync ecommerce-dev
```

### Step 3: Verify Rollout is Created

```bash
# Check rollout status
kubectl argo rollouts get rollout backend -n ecommerce-dev

# Or using kubectl
kubectl get rollout backend -n ecommerce-dev
```

## 🎮 Usage

### Trigger a Canary Deployment

**Method 1: Update Image Tag (GitOps)**

```bash
# Update image tag in gitops/overlays/dev/kustomization.yaml
images:
  - name: ecommerce-backend
    newName: ghcr.io/YOUR_USERNAME/argo-app/backend
    newTag: v1.0.50  # ← Change to new version

# Commit and push
git add gitops/overlays/dev/kustomization.yaml
git commit -m "deploy: backend v1.0.50"
git push origin main

# ArgoCD will sync and start canary rollout
```

**Method 2: Direct kubectl**

```bash
# Set new image
kubectl argo rollouts set image backend \
  backend=ghcr.io/YOUR_USERNAME/argo-app/backend:v1.0.50 \
  -n ecommerce-dev
```

### Monitor Canary Progress

```bash
# Watch rollout progress
kubectl argo rollouts get rollout backend -n ecommerce-dev --watch

# View in dashboard
kubectl port-forward -n argo-rollouts svc/argo-rollouts-dashboard 3100:3100
# Open: http://localhost:3100
```

### Manual Promotion

```bash
# Promote to next step
kubectl argo rollouts promote backend -n ecommerce-dev

# Skip all steps and promote immediately
kubectl argo rollouts promote backend -n ecommerce-dev --full
```

### Abort Rollout

```bash
# Abort and rollback to stable version
kubectl argo rollouts abort backend -n ecommerce-dev
```

## 📊 Monitoring

### Check Rollout Status

```bash
# Get rollout status
kubectl argo rollouts status backend -n ecommerce-dev

# Get detailed info
kubectl argo rollouts get rollout backend -n ecommerce-dev

# View history
kubectl argo rollouts history backend -n ecommerce-dev
```

### View Traffic Split

```bash
# Check current traffic distribution
kubectl get rollout backend -n ecommerce-dev -o jsonpath='{.status.canary.weights}'

# Check pod distribution
kubectl get pods -n ecommerce-dev -l app=backend --show-labels
```

### View Analysis Results

```bash
# Get analysis runs
kubectl get analysisrun -n ecommerce-dev

# Describe analysis run
kubectl describe analysisrun <analysis-run-name> -n ecommerce-dev
```

## 🔄 Rollback

### Automatic Rollback

If analysis fails, Argo Rollouts automatically rolls back:

```bash
# Check if rollback occurred
kubectl argo rollouts get rollout backend -n ecommerce-dev

# View events
kubectl describe rollout backend -n ecommerce-dev
```

### Manual Rollback

```bash
# Abort current rollout
kubectl argo rollouts abort backend -n ecommerce-dev

# Rollback to previous version
kubectl argo rollouts undo backend -n ecommerce-dev

# Rollback to specific revision
kubectl argo rollouts undo backend --to-revision=3 -n ecommerce-dev
```

## 🎯 Advanced Features

### Blue-Green Deployment

Modify `rollout.yaml` to use blue-green strategy:

```yaml
spec:
  strategy:
    blueGreen:
      activeService: backend
      previewService: backend-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
```

### Automated Analysis with Prometheus

The included `analysis-template.yaml` monitors:
- **Success Rate**: Must be ≥ 95%
- **Error Rate**: Must be ≤ 5%
- **Response Time (p95)**: Must be ≤ 500ms

To use automated analysis:

1. **Install Prometheus** (if not already installed):
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

2. **Update Prometheus URL** in `analysis-template.yaml` if needed

3. **Analysis runs automatically** during canary steps

### Custom Analysis Metrics

Add custom metrics to `analysis-template.yaml`:

```yaml
metrics:
- name: custom-metric
  interval: 30s
  successCondition: result[0] >= 0.99
  provider:
    prometheus:
      address: "{{args.prometheus-url}}"
      query: |
        your_custom_prometheus_query
```

### Notifications

Configure notifications for rollout events:

```yaml
# Add to rollout.yaml
spec:
  strategy:
    canary:
      analysis:
        templates:
        - templateName: backend-success-rate
        args:
        - name: slack-webhook
          value: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## 🛠️ Troubleshooting

### Rollout Stuck in Progressing

```bash
# Check rollout status
kubectl argo rollouts get rollout backend -n ecommerce-dev

# Check events
kubectl describe rollout backend -n ecommerce-dev

# Check pods
kubectl get pods -n ecommerce-dev -l app=backend

# Manually promote if needed
kubectl argo rollouts promote backend -n ecommerce-dev
```

### Analysis Failing

```bash
# Check analysis runs
kubectl get analysisrun -n ecommerce-dev

# Describe failed analysis
kubectl describe analysisrun <name> -n ecommerce-dev

# Check Prometheus connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://prometheus.monitoring.svc.cluster.local:9090/-/healthy
```

### Traffic Not Splitting

```bash
# Verify NGINX ingress controller supports traffic splitting
kubectl get ingress ecommerce-ingress -n ecommerce-dev -o yaml

# Check canary annotations
kubectl get ingress ecommerce-ingress -n ecommerce-dev -o jsonpath='{.metadata.annotations}'

# Verify services exist
kubectl get svc -n ecommerce-dev | grep backend
```

## 📚 Best Practices

1. **Start with Manual Promotion**: Test canary process manually before enabling auto-promotion
2. **Monitor Metrics**: Always watch metrics during canary rollout
3. **Set Appropriate Thresholds**: Adjust success criteria based on your SLOs
4. **Use Analysis Templates**: Automate promotion/rollback decisions
5. **Test Rollback**: Regularly test rollback procedures
6. **Document Incidents**: Keep track of failed rollouts and learnings
7. **Gradual Rollout**: Don't rush - let each step run its full duration
8. **Have Runbooks**: Document procedures for common issues

## 🔗 Additional Resources

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Canary Deployment Best Practices](https://argoproj.github.io/argo-rollouts/features/canary/)
- [Analysis and Progressive Delivery](https://argoproj.github.io/argo-rollouts/features/analysis/)
- [Traffic Management](https://argoproj.github.io/argo-rollouts/features/traffic-management/)

## 📝 Quick Reference

```bash
# Common Commands
kubectl argo rollouts get rollout backend -n ecommerce-dev --watch
kubectl argo rollouts promote backend -n ecommerce-dev
kubectl argo rollouts abort backend -n ecommerce-dev
kubectl argo rollouts undo backend -n ecommerce-dev
kubectl argo rollouts status backend -n ecommerce-dev
kubectl argo rollouts history backend -n ecommerce-dev

# Dashboard
kubectl port-forward -n argo-rollouts svc/argo-rollouts-dashboard 3100:3100

# Analysis
kubectl get analysisrun -n ecommerce-dev
kubectl describe analysisrun <name> -n ecommerce-dev
```

---

**Made with Bob** 🤖