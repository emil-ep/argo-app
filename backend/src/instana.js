// Instana tracing initialization
// This file MUST be required before any other modules

// Build the reporting URL for Instana SaaS
const agentHost = process.env.INSTANA_AGENT_HOST || 'ingress-red-saas.instana.io';
const agentPort = process.env.INSTANA_AGENT_PORT || '42699';
const reportingUrl = `https://${agentHost}:${agentPort}`;

require('@instana/collector')({
  tracing: {
    enabled: process.env.INSTANA_ENABLED !== 'false',
    automaticTracingEnabled: true,
    stackTraceLength: 10,
  },
  reportingUrl: reportingUrl,
  agentKey: process.env.INSTANA_AGENT_KEY,
  serviceName: process.env.INSTANA_SERVICE_NAME || 'ecommerce-backend',
  tags: {
    environment: process.env.NODE_ENV || 'development',
    component: 'backend',
    version: process.env.APP_VERSION || '1.0.0',
  },
});

console.log(`Instana tracing initialized - Reporting to: ${reportingUrl}`);

// Made with Bob