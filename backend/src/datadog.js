// Datadog APM tracing initialization
// This file MUST be required before any other modules

const tracer = require('dd-trace');

const isDatadogEnabled = process.env.DD_APM_ENABLED !== 'false' && (process.env.DD_AGENT_HOST || process.env.DD_API_KEY || process.env.DD_ENV);

if (isDatadogEnabled) {
  tracer.init({
    service: process.env.DD_SERVICE || 'ecommerce-backend',
    env: process.env.DD_ENV || process.env.NODE_ENV || 'development',
    version: process.env.DD_VERSION || process.env.APP_VERSION || '1.0.0',
    hostname: process.env.DD_AGENT_HOST || 'localhost',
    port: parseInt(process.env.DD_TRACE_AGENT_PORT, 10) || 8126,
    logInjection: true,
    runtimeMetrics: true,
    profiling: process.env.DD_PROFILING_ENABLED === 'true',
  });
  console.log(`Datadog APM tracing initialized for service: ${process.env.DD_SERVICE || 'ecommerce-backend'} (Agent host: ${process.env.DD_AGENT_HOST || 'localhost'})`);
}

module.exports = tracer;
