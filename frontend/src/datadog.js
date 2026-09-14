import { datadogRum } from '@datadog/browser-rum';

export function initDatadogRum() {
  const env = window.ENV || {};
  const applicationId = env.DD_APPLICATION_ID || import.meta.env.VITE_DD_APPLICATION_ID;
  const clientToken = env.DD_CLIENT_TOKEN || import.meta.env.VITE_DD_CLIENT_TOKEN;
  const site = env.DD_SITE || import.meta.env.VITE_DD_SITE || 'datadoghq.com';
  const service = env.DD_SERVICE || 'ecommerce-frontend';
  const environment = env.DD_ENV || 'development';
  const version = env.DD_VERSION || '1.0.0';
  const apiUrl = env.API_URL || 'http://localhost:3000';

  if (!applicationId || !clientToken || applicationId.startsWith('CHANGE_ME') || clientToken.startsWith('CHANGE_ME')) {
    return;
  }

  try {
    datadogRum.init({
      applicationId,
      clientToken,
      site,
      service,
      env: environment,
      version,
      sessionSampleRate: 100,
      sessionReplaySampleRate: 20,
      trackUserInteractions: true,
      trackResources: true,
      trackLongTasks: true,
      defaultPrivacyLevel: 'mask-user-input',
      allowedTracingUrls: [
        {
          match: (url) => url.startsWith(apiUrl) || url.includes('/api/'),
          propagatorTypes: ['datadog', 'tracecontext'],
        },
      ],
    });

    datadogRum.startSessionReplayRecording();
  } catch (err) {
    console.warn('Failed to initialize Datadog RUM:', err);
  }
}

// Made with Bob
