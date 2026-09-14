#!/bin/sh
set -e

# Replace environment variables in env.js
envsubst '${API_URL} ${INSTANA_EUM_KEY} ${INSTANA_EUM_URL} ${DD_APPLICATION_ID} ${DD_CLIENT_TOKEN} ${DD_SITE} ${DD_SERVICE} ${DD_ENV} ${DD_VERSION}' < /usr/share/nginx/html/env.js.template > /usr/share/nginx/html/env.js

# Execute the CMD
exec "$@"
