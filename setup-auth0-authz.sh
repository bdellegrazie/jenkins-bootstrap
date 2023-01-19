#!/bin/bash -eu
# Unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Auth0... Jenkins Local Deploy Client
AUTH0_JENKINS_CLIENT_ID="$(cat ${script_dir}/auth0/Jenkins-Local.id)"
AUTH0_JENKINS_CLIENT_SECRET="$(cat ${script_dir}/auth0/Jenkins-Local.secret)"  # pragma: allowlist secret
AUTH0_TENANT_URL="https://dev-bdellegrazie.eu.auth0.com"

AUTH0_MGMT_OAUTH="${AUTH0_TENANT_URL}/oauth/token"
AUTH0_MGMT_API="${AUTH0_TENANT_URL}/api/v2"

# Get Mgmt API Token for Auth0 Authorization API
AUTH0_AUTHZ_API="https://dev-bdellegrazie.eu8.webtask.io/adf6e2f2b84784b57522e3b19dfc9201/api"
AUTH0_AUTHZ_AUDIENCE="urn:auth0-authz-api"
AUTH0_AUTHZ_API_TOKEN=$(curl --silent --fail --max-time 10 --request POST \
  --url "${AUTH0_MGMT_OAUTH}" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --data-binary @- << EOF | jq -c -e '.access_token'
{
  "client_id": "${AUTH0_JENKINS_CLIENT_ID}",
  "client_secret": "${AUTH0_JENKINS_CLIENT_SECRET}",
  "audience": "${AUTH0_AUTHZ_AUDIENCE}",
  "grant_type": "client_credentials"
}
EOF
)
AUTH0_AUTHZ_API_TOKEN="${AUTH0_AUTHZ_API_TOKEN%\"}"
AUTH0_AUTHZ_API_TOKEN="${AUTH0_AUTHZ_API_TOKEN#\"}"

# Get Groups
curl --silent --fail --max-time 10 --request GET \
  --url "${AUTH0_AUTHZ_API}/groups" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer ${AUTH0_AUTHZ_API_TOKEN}"

# Get Mappings
curl --silent --fail --max-time 10 --request GET \
  --url "${AUTH0_AUTHZ_API}/groups/90349dfb-2495-4968-8f20-5f6ecd8107f1/roles" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer ${AUTH0_AUTHZ_API_TOKEN}"
