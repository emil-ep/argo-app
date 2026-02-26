# Instana Tracing Setup Guide

This guide explains the Instana tracing integration for the e-commerce application, covering backend APM (Application Performance Monitoring) and frontend EUM (End User Monitoring).

## Overview

The application is instrumented with Instana to provide:

### Backend Tracing (APM)
- **HTTP Request/Response Tracing**: All API endpoints are automatically traced
- **Database Query Monitoring**: PostgreSQL queries via Sequelize are captured
- **Performance Metrics**: Response times, throughput, error rates
- **Distributed Tracing**: End-to-end request flow visibility
- **Error Tracking**: Automatic capture of exceptions and errors

### Frontend Monitoring (EUM)
- **Page Load Performance**: Initial load times and resource loading
- **User Interactions**: Clicks, form submissions, navigation
- **AJAX/Fetch Requests**: API calls from the browser
- **JavaScript Errors**: Runtime errors and stack traces
- **Single Page Application (SPA) Tracking**: Route changes in React

### Database Monitoring
- **Query Performance**: Execution times for all SQL queries
- **Connection Pool Metrics**: Database connection usage
- **Slow Query Detection**: Automatic identification of performance issues
- Monitored automatically through backend instrumentation

## Configuration

### Instana Credentials

The application uses the following Instana configuration:

```yaml
Agent Endpoint: ingress-red-saas.instana.io
Agent Port: 443
Agent Key: Vjd1MHFkNW5SV0tQUWVBR1p4M1J4QQ==
EUM Key: Vjd1MHFkNW5SV0tQUWVBR1p4M1J4QQ==
EUM URL: https://eum.instana.io
```

### Backend Configuration

**Location**: `backend/src/instana.js`

The Instana collector is initialized before any other modules to ensure proper instrumentation:

```javascript
require('@instana/collector')({
  tracing: {
    enabled: true,
    automaticTracingEnabled: true,
    stackTraceLength: 10,
  },
  reporting: {
    host: 'ingress-red-saas.instana.io',
    port: 443,
    protocol: 'https',
  },
  agentKey: process.env.INSTANA_AGENT_KEY,
  serviceName: 'ecommerce-backend',
});
```

**Environment Variables**:
- `INSTANA_ENABLED`: Enable/disable tracing (default: true)
- `INSTANA_AGENT_HOST`: Instana agent endpoint
- `INSTANA_AGENT_PORT`: Instana agent port
- `INSTANA_AGENT_KEY`: Authentication key
- `INSTANA_SERVICE_NAME`: Service identifier in Instana

### Frontend Configuration

**Location**: `frontend/index.html`

Instana EUM is loaded via script tag and configured with environment variables:

```javascript
ineum('reportingUrl', window.ENV.INSTANA_EUM_URL);
ineum('key', window.ENV.INSTANA_EUM_KEY);
ineum('trackSessions');
```

**Environment Variables**:
- `INSTANA_EUM_KEY`: Frontend monitoring key
- `INSTANA_EUM_URL`: EUM reporting endpoint

## Kubernetes Configuration

### Backend ConfigMap

**File**: `gitops/base/backend/configmap.yaml`

```yaml
data:
  instana.enabled: "true"
  instana.agent.host: "ingress-red-saas.instana.io"
  instana.agent.port: "443"
  instana.service.name: "ecommerce-backend"
```

### Backend Secret

**File**: `gitops/base/backend/secret.yaml`

```yaml
stringData:
  instana.agent.key: "Vjd1MHFkNW5SV0tQUWVBR1p4M1J4QQ=="
```

### Frontend ConfigMap

**File**: `gitops/base/frontend/configmap.yaml`

```yaml
data:
  instana.eum.key: "Vjd1MHFkNW5SV0tQUWVBR1p4M1J4QQ=="
  instana.eum.url: "https://eum.instana.io"
```

## Deployment

### 1. Update Dependencies

The backend requires the Instana collector package:

```bash
cd backend
npm install
```

### 2. Build Docker Images

```bash
# Backend
cd backend
docker build -t ecommerce-backend:latest .

# Frontend
cd frontend
docker build -t ecommerce-frontend:latest .
```

### 3. Deploy via ArgoCD

```bash
# Commit and push changes
git add .
git commit -m "Add Instana tracing integration"
git push

# Sync ArgoCD application
argocd app sync ecommerce-dev
```

### 4. Verify Deployment

```bash
# Check backend pods
kubectl logs -n ecommerce-dev deployment/backend | grep "Instana"
# Should show: "Instana tracing initialized"

# Check frontend pods
kubectl exec -n ecommerce-dev deployment/frontend -- cat /usr/share/nginx/html/env.js
# Should show Instana EUM configuration
```

## Viewing Traces in Instana

### Backend Traces

1. **Navigate to Applications**: Go to Applications → ecommerce-backend
2. **View Service Map**: See the complete service topology
3. **Analyze Calls**: Click on any service to see detailed traces
4. **Database Queries**: View PostgreSQL query performance
5. **Error Analysis**: Check the Errors tab for exceptions

### Frontend Monitoring

1. **Navigate to Websites**: Go to Websites & Mobile Apps
2. **Select Application**: Choose your frontend application
3. **Page Loads**: View page load performance metrics
4. **User Actions**: See user interactions and clicks
5. **AJAX Calls**: Monitor API requests from the browser
6. **JavaScript Errors**: View runtime errors with stack traces

### Key Metrics to Monitor

**Backend**:
- Response time (p50, p95, p99)
- Throughput (requests per second)
- Error rate
- Database query performance
- External API call latency

**Frontend**:
- Page load time
- Time to interactive
- AJAX request duration
- JavaScript error rate
- User session duration

## Troubleshooting

### Backend Not Reporting

**Check logs**:
```bash
kubectl logs -n ecommerce-dev deployment/backend | grep -i instana
```

**Common issues**:
- Agent key incorrect: Verify `INSTANA_AGENT_KEY` in Secret
- Network connectivity: Ensure pods can reach `ingress-red-saas.instana.io:443`
- Instana not initialized first: Check that `require('./instana')` is the first line in `server.js`

### Frontend Not Reporting

**Check browser console**:
```javascript
// Should see Instana EUM loaded
console.log(window.ineum);
```

**Common issues**:
- EUM key not set: Check `window.ENV.INSTANA_EUM_KEY`
- Script blocked: Check browser console for CSP errors
- Configuration not injected: Verify `docker-entrypoint.sh` is running

### No Database Traces

Database queries are automatically traced through Sequelize. If not visible:
- Ensure backend tracing is working
- Check that queries are actually being executed
- Verify Sequelize is properly configured

## Disabling Instana

To temporarily disable Instana tracing:

### Backend
```bash
kubectl set env deployment/backend INSTANA_ENABLED=false -n ecommerce-dev
```

### Frontend
Remove or comment out the Instana script in `frontend/index.html`

## Performance Impact

Instana is designed for production use with minimal overhead:

**Backend**:
- CPU overhead: < 1%
- Memory overhead: ~50MB
- Latency impact: < 1ms per request

**Frontend**:
- Script size: ~50KB (gzipped)
- Performance impact: Negligible
- Async loading: Does not block page rendering

## Best Practices

1. **Service Naming**: Use descriptive service names for easy identification
2. **Custom Tags**: Add business context with custom tags
3. **Error Handling**: Ensure errors are properly thrown for Instana to capture
4. **Sampling**: Use sampling in high-traffic scenarios (configured in Instana UI)
5. **Sensitive Data**: Avoid logging sensitive information in traces

## Additional Resources

- [Instana Node.js Documentation](https://www.ibm.com/docs/en/instana-observability/current?topic=technologies-monitoring-nodejs)
- [Instana EUM Documentation](https://www.ibm.com/docs/en/instana-observability/current?topic=websites-mobile-apps)
- [Instana Best Practices](https://www.ibm.com/docs/en/instana-observability/current?topic=instana-best-practices)

## Support

For issues with Instana integration:
1. Check the troubleshooting section above
2. Review Instana agent logs
3. Contact Instana support with trace IDs

---

**Made with Bob**