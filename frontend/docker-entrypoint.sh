#!/bin/sh
set -e

# Replace environment variables in env.js
envsubst '${API_URL}' < /usr/share/nginx/html/env.js.template > /usr/share/nginx/html/env.js

# Execute the CMD
exec "$@"

# Made with Bob
