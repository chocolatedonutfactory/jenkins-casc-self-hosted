#!/bin/bash
set -e

# Wait for healthchecks to pass (if using docker compose wait) or just poll manually
# Assuming docker compose wait is available in CI (Compose V2)

echo "Starting validation..."

# Load .env if it exists
if [ -f .env ]; then
  echo "Loading .env file..."
  # Use a subshell to avoid polluting the current shell, but we want the variables here.
  # This simple parser handles basic VAR=VAL lines.
  set -a
  source .env
  set +a
fi

DOMAIN=${LAB_DOMAIN:-localhost}
PORT_JENKINS=${NGINX_JENKINS_PORT:-8443}
PORT_KEYCLOAK=${NGINX_KEYCLOAK_PORT:-8444}
REALM=${KC_REALM_NAME:-jenkins-lab}

# Function to check URL with retries
check_url() {
  url=$1
  name=$2
  max_retries=12 # 12 * 5s = 60s (plus the docker compose wait time)
  wait_seconds=5

  for ((i=1;i<=max_retries;i++)); do
    echo "Attempt $i/$max_retries: Checking $name at $url..."
    code=$(curl -k -s -o /dev/null -w "%{http_code}" "$url")
    
    if [[ "$code" =~ ^(200|403|302|401)$ ]]; then
      echo "SUCCESS: $name is UP! (Status: $code)"
      return 0
    fi
    echo "Waiting... (Status: $code)"
    sleep $wait_seconds
  done
  echo "FAILURE: $name failed to respond with success code after $((max_retries * wait_seconds)) seconds."
  return 1
}

# 1. Check Jenkins Login Page
check_url "https://${DOMAIN}:${PORT_JENKINS}/" "Jenkins"

# 2. Check Keycloak Discovery Endpoint (Public) - Expect 200
check_url "https://${DOMAIN}:${PORT_KEYCLOAK}/realms/${REALM}/.well-known/openid-configuration" "Keycloak Discovery"

echo "Environment validation successful!"
