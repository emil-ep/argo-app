// Instana tracing initialization
// This file MUST be required before any other modules

// Check if Instana is enabled
const instanaEnabled = process.env.INSTANA_ENABLED !== 'false';

if (instanaEnabled) {
  const agentHost = process.env.INSTANA_AGENT_HOST || 'ingress-red-saas.instana.io';
  const agentPort = parseInt(process.env.INSTANA_AGENT_PORT || '443', 10);
  const agentKey = process.env.INSTANA_AGENT_KEY;
  const serviceName = process.env.INSTANA_SERVICE_NAME || 'ecommerce-backend';

  // Validate required configuration
  if (!agentKey || agentKey === 'CHANGE_ME_INSTANA_AGENT_KEY') {
    console.warn('⚠️  Instana agent key not configured. Tracing will not work.');
    console.warn('   Set INSTANA_AGENT_KEY environment variable with your actual agent key.');
  } else {
    console.log('✓ Initializing Instana tracing...');
    console.log(`  Service: ${serviceName}`);
    console.log(`  Agent: ${agentHost}:${agentPort}`);
    console.log(`  Key: ${agentKey.substring(0, 8)}...`);

    require('@instana/collector')({
      tracing: {
        enabled: true,
        automaticTracingEnabled: true,
        stackTraceLength: 10,
      },
      reporting: {
        host: agentHost,
        port: agentPort,
        protocol: 'https',
      },
      agentKey: agentKey,
      serviceName: serviceName,
      tags: {
        environment: process.env.NODE_ENV || 'development',
        component: 'backend',
        version: process.env.APP_VERSION || '1.0.0',
      },
    });

    console.log('✓ Instana tracing initialized successfully');
  }
} else {
  console.log('ℹ️  Instana tracing is disabled (INSTANA_ENABLED=false)');
}

// Made with Bob