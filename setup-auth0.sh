#!/bin/bash -eu
# Unofficial bash strict mode
set -o pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

urlencode() {
  # urlencode <string>
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
      *) printf '%%%02X' "'$c"
    esac
  done
}

source "${script_dir}/.env"

# Auth0...
AUTH0_TENANT_URL="https://dev-bdellegrazie.eu.auth0.com"
AUTH0_JENKINS_CLIENT_ID="$(cat ${script_dir}/auth0/Jenkins-Local.id)"
AUTH0_JENKINS_CLIENT_SECRET="$(cat ${script_dir}/auth0/Jenkins-Local.secret)"  # pragma: allowlist secret
AUTH0_SAML_METADATA_URL="${AUTH0_TENANT_URL}/samlp/metadata/${AUTH0_JENKINS_CLIENT_ID}"
AUTH0_SAML_LOGOUT_REDIRECT_URL="https://github.com/bdellegrazie/jenkins-bootstrap"
AUTH0_SAML_LOGOUT_URL="${AUTH0_TENANT_URL}/v2/logout?client_id=${AUTH0_JENKINS_CLIENT_ID}&returnTo=$(urlencode ${AUTH0_SAML_LOGOUT_REDIRECT_URL})"

cat >> "${script_dir}/.env" <<END
AUTH0_OIDC_BASE_URL="${AUTH0_TENANT_URL}"
END
#AUTH0_SAML_METADATA_URL=${AUTH0_SAML_METADATA_URL}
#AUTH0_SAML_LOGOUT_URL=${AUTH0_SAML_LOGOUT_URL}

AUTH0_MGMT_OAUTH="${AUTH0_TENANT_URL}/oauth/token"
AUTH0_MGMT_API="${AUTH0_TENANT_URL}/api/v2"

# Get Mgmt API Token
AUTH0_MGMT_API_TOKEN=$(curl --silent --fail --max-time 10 --request POST \
  --url "${AUTH0_MGMT_OAUTH}" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --data-binary @- << EOF | jq -c -e '.access_token'
{
  "client_id": "${AUTH0_JENKINS_CLIENT_ID}",
  "client_secret": "${AUTH0_JENKINS_CLIENT_SECRET}",
  "audience": "${AUTH0_MGMT_API}/",
  "grant_type": "client_credentials"
}
EOF
)
AUTH0_MGMT_API_TOKEN="${AUTH0_MGMT_API_TOKEN%\"}"
AUTH0_MGMT_API_TOKEN="${AUTH0_MGMT_API_TOKEN#\"}"

# Update Jenkins URL in Jenkins Auth0 Client
curl --silent --fail --max-time 10 --output /dev/null --request PATCH \
  --url "${AUTH0_MGMT_API}/clients/${AUTH0_JENKINS_CLIENT_ID}" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer ${AUTH0_MGMT_API_TOKEN}" \
  --data-binary @- <<EOF
{
  "addons": {
    "samlp": {
      "audience": "${JENKINS_PUBLIC_URL}/securityRealm/finishLogin",
      "logout": {
        "callback": "${JENKINS_PUBLIC_URL}/logout"
      }
    }
  },
  "allowed_logout_urls": [
    "${AUTH0_SAML_LOGOUT_REDIRECT_URL}"
  ],
  "callbacks":[
    "${JENKINS_PUBLIC_URL}/securityRealm/finishLogin"
  ],
  "initiate_login_uri": "${JENKINS_PUBLIC_URL}",
  "logo_uri": "https://jenkins.io/images/logos/jenkins/jenkins.svg"
}
EOF
