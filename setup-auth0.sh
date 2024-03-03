#!/bin/bash -eu
# Unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function urlencode() {
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

declare __AUTH0_CURL_OPTS=("--silent" "--show-error" "--fail" "--max-time" "10")

function auth0_get_management_token() {
  # $1 = tenant URL
  # $2 = clientID
  # $3 = clientSecret
  local -r AUTH0_MGMT_OAUTH="${1}/oauth/token"
  local -r AUTH0_MGMT_API="${1}/api/v2"
  local -r CLIENT_ID="${2:?Client ID required}"
  local -r CLIENT_SECRET="${3:?Client secret required}"
  shift 3

  # Get Mgmt API Token
  local AUTH0_MGMT_API_TOKEN=$(curl ${__AUTH0_CURL_OPTS[@]} --request POST \
    --url "${AUTH0_MGMT_OAUTH}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-binary @- << EOF | jq -c -e '.access_token'
{
  "client_id": "${CLIENT_ID}",
  "client_secret": "${CLIENT_SECRET}",
  "audience": "${AUTH0_MGMT_API}/",
  "grant_type": "client_credentials"
}
EOF
  )
  AUTH0_MGMT_API_TOKEN="${AUTH0_MGMT_API_TOKEN%\"}"
  AUTH0_MGMT_API_TOKEN="${AUTH0_MGMT_API_TOKEN#\"}"
  echo -n "${AUTH0_MGMT_API_TOKEN}"
}

function auth0_get_application_clients() {
  # $1 = Tenant url
  # $2 = MGMT Token
  local AUTH0_MGMT_API="${1}/api/v2"
  local MGMT_TOKEN="${2}"
  shift 2

  curl ${__AUTH0_CURL_OPTS[@]} --get \
    --url "${AUTH0_MGMT_API}/clients" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer ${MGMT_TOKEN}" \
    ${@}
}

function auth0_get_application_client() {
  # $1 = Tenant url
  # $2 = MGMT Token
  # $3 = Client ID
  local -r AUTH0_MGMT_API="${1}/api/v2"
  local -r MGMT_TOKEN="${2}"
  local -r CLIENT_ID="${3}"
  shift 3

  curl ${__AUTH0_CURL_OPTS[@]} --get \
    --url "${AUTH0_MGMT_API}/clients/${CLIENT_ID}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer ${MGMT_TOKEN}" \
    ${@}
}

function auth0_patch_application_client() {
  # $1 = tenant url
  # $2 = MGMT Token
  # $3 = client ID
  local -r AUTH0_MGMT_API="${1}/api/v2"
  local -r MGMT_TOKEN="${2}"
  local -r CLIENT_ID="${3}"
  shift 3

  curl ${__AUTH0_CURL_OPTS[@]} --output /dev/null --request PATCH \
    --url "${AUTH0_MGMT_API}/clients/${CLIENT_ID}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer ${MGMT_TOKEN}" \
    ${@}
}

function auth0_get_tenant_pem() {
  # $1 = tenant url
  local -r AUTH0_PEM_URL="${1}/pem"
  shift 1

  curl ${__AUTH0_CURL_OPTS[@]} --get \
    --url "${AUTH0_PEM_URL}" \
    ${@}
}

function auth0_lookup_client() {
  # $1 = tenant name, $2 = client name, $3 = item to lookup
  # stdin = contents to examine
  jq -r --arg tenant "${1}" --arg name "${2}" --arg item "${3}" '.[] | select(.tenant==$tenant) | select(.name==$name) | .[$item]'
}

source "${script_dir}/.env"

declare -r work_dir="$(mktemp -d -t auth0.XXX)"
cleanup() {
  local -r ret="$?"
  rm -rf "${work_dir}"
  return "${ret}"
}
trap cleanup EXIT

# Auth0...
AUTH0_TENANT="$(jq -r '.tenant' "${script_dir}/auth0/tenant.json.secret")"
AUTH0_TENANT_DOMAIN="$(jq -r '.domain' "${script_dir}/auth0/tenant.json.secret")"
AUTH0_TENANT_URL="https://${AUTH0_TENANT_DOMAIN}"
AUTH0_TENANT_SAML_ISSUER="urn:${AUTH0_TENANT_DOMAIN}"
AUTH0_TENANT_CUSTOM_CLAIMS_NS="https://${AUTH0_TENANT}/claims"
AUTH0_SAML_LOGOUT_REDIRECT_URL="https://github.com/bdellegrazie/jenkins-bootstrap"
AUTH0_MGMT_CLIENT_ID="$(jq -r '.management.clientId' "${script_dir}/auth0/tenant.json.secret")"
AUTH0_MGMT_CLIENT_SECRET="$(jq -r '.management.clientSecret' "${script_dir}/auth0/tenant.json.secret")"
AUTH0_JENKINS_CLIENT_NAME="Jenkins-Local"
AUTH0_SONARQUBE_CLIENT_NAME="Sonarqube-Local"
AUTH0_DTRACK_CLIENT_NAME="DependencyTrack-Local"

AUTH0_MGMT_API_TOKEN="$(auth0_get_management_token "${AUTH0_TENANT_URL}" "${AUTH0_MGMT_CLIENT_ID}" "${AUTH0_MGMT_CLIENT_SECRET}")"
auth0_get_application_clients "${AUTH0_TENANT_URL}" "${AUTH0_MGMT_API_TOKEN}" --output "${work_dir}/tenants.json" \
 --data "fields=client_id,client_secret,name" --data "include_fields=true" --data "is_first_party=true"

AUTH0_JENKINS_CLIENT_ID="$(cat "${work_dir}/tenants.json" | auth0_lookup_client "${AUTH0_TENANT}" "${AUTH0_JENKINS_CLIENT_NAME}" client_id)"
AUTH0_JENKINS_CLIENT_SECRET="$(cat "${work_dir}/tenants.json" | auth0_lookup_client "${AUTH0_TENANT}" "${AUTH0_JENKINS_CLIENT_NAME}" client_secret)"
AUTH0_JENKINS_SAML_METADATA_URL="${AUTH0_TENANT_URL}/samlp/metadata/${AUTH0_JENKINS_CLIENT_ID}"
AUTH0_JENKINS_SAML_LOGOUT_REDIRECT_URL="${AUTH0_TENANT_URL}/v2/logout?client_id=${AUTH0_JENKINS_CLIENT_ID}&returnTo=$(urlencode ${AUTH0_SAML_LOGOUT_REDIRECT_URL})"

AUTH0_SONARQUBE_CLIENT_ID="$(cat "${work_dir}/tenants.json" | auth0_lookup_client "${AUTH0_TENANT}" "${AUTH0_SONARQUBE_CLIENT_NAME}" client_id)"
AUTH0_SONARQUBE_CLIENT_SECRET="$(cat "${work_dir}/tenants.json" | auth0_lookup_client "${AUTH0_TENANT}" "${AUTH0_JENKINS_CLIENT_NAME}" client_secret)"
AUTH0_SONARQUBE_SAML_METADATA_URL="${AUTH0_TENANT_URL}/samlp/metadata/${AUTH0_SONARQUBE_CLIENT_ID}"
AUTH0_SONARQUBE_SAML_LOGOUT_REDIRECT_URL="${AUTH0_TENANT_URL}/v2/logout?client_id=${AUTH0_SONARQUBE_CLIENT_ID}&returnTo=$(urlencode ${AUTH0_SAML_LOGOUT_REDIRECT_URL})"

AUTH0_DTRACK_CLIENT_ID="$(cat "${work_dir}/tenants.json" | auth0_lookup_client "${AUTH0_TENANT}" "${AUTH0_DTRACK_CLIENT_NAME}" client_id)"
#AUTH0_DTRACK_CLIENT_SECRET="$(cat "${work_dir}/tenants.json" | auth0_lookup_client "${AUTH0_TENANT}" "${AUTH0_JENKINS_CLIENT_NAME}" client_secret)"
AUTH0_DTRACK_OIDC_METADATA_URL="${AUTH0_TENANT_URL}"
AUTH0_DTRACK_USERNAME_CLAIM="nickname"
AUTH0_DTRACK_TEAMS_CLAIM="https://dev-bdellegrazie/claims/roles"

cat >> "${script_dir}/.env" <<END
AUTH0_TENANT_BASE_URL="${AUTH0_TENANT_URL}"
AUTH0_TENANT_CUSTOM_CLAIMS_NS="${AUTH0_TENANT_CUSTOM_CLAIMS_NS}"
AUTH0_DTRACK_CLIENT_ID="${AUTH0_DTRACK_CLIENT_ID}"
AUTH0_DTRACK_USERNAME_CLAIM="${AUTH0_DTRACK_USERNAME_CLAIM}"
AUTH0_DTRACK_TEAMS_CLAIM="${AUTH0_DTRACK_TEAMS_CLAIM}"
AUTH0_JENKINS_SAML_METADATA_URL="${AUTH0_JENKINS_SAML_METADATA_URL}"
AUTH0_JENKINS_SAML_LOGOUT_REDIRECT_URL="${AUTH0_JENKINS_SAML_LOGOUT_REDIRECT_URL}"
END

# Update Jenkins URL in Jenkins Auth0 Client
auth0_patch_application_client "${AUTH0_TENANT_URL}" "${AUTH0_MGMT_API_TOKEN}" "${AUTH0_JENKINS_CLIENT_ID}" --data-binary @- <<EOF
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
    "${AUTH0_JENKINS_SAML_LOGOUT_REDIRECT_URL}"
  ],
  "callbacks":[
    "${JENKINS_PUBLIC_URL}/securityRealm/finishLogin"
  ],
  "initiate_login_uri": "${JENKINS_PUBLIC_URL}",
  "logo_uri": "https://jenkins.io/images/logos/jenkins/jenkins.svg"
}
EOF

# Update Sonarqube URL in Sonarqube Auth0 Client
auth0_patch_application_client "${AUTH0_TENANT_URL}" "${AUTH0_MGMT_API_TOKEN}" "${AUTH0_SONARQUBE_CLIENT_ID}" --data-binary @- <<EOF
{
  "addons": {
    "samlp": {
      "mappings": {
        "user_id": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier",
        "email": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
        "name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name",
        "given_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
        "family_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname",
        "upn": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn",
        "https://dev-bdellegrazie/claims/roles": "http://schemas.xmlsoap.org/claims/Group"
      },
      "signatureAlgorithm": "rsa-sha256",
      "digestAlgorithm": "sha256"
    }
  },
  "allowed_logout_urls": [
    "${AUTH0_SONARQUBE_SAML_LOGOUT_REDIRECT_URL}"
  ],
  "callbacks":[
    "${SONARQUBE_PUBLIC_URL}/oauth2/callback/saml"
  ],
  "initiate_login_uri": "${SONARQUBE_PUBLIC_URL}",
  "logo_uri": "https://assets-eu-01.kc-usercontent.com/e1f3885c-805a-0150-804f-0996e00cd37d/afadf76d-420e-414d-acff-4a9efb344baa/SonarQubeIcon.svg?w=150&h=150&auto=format&fit=crop"
}
EOF

AUTH0_TENANT_SAML_PEM_AS_PROP="$(auth0_get_tenant_pem "${AUTH0_TENANT_URL}" | tr -d '\r' | sed -E -e 's|$|\\|g')"

cat > "${script_dir}/sonarqube/auth/saml.properties" <<END
#
# https://docs.sonarqube.org/8.9/instance-administration/delegating-authentication/#saml-authentication
sonar.auth.saml.enabled=true
sonar.auth.saml.applicationId=${AUTH0_SONARQUBE_CLIENT_ID}
sonar.auth.saml.providerName=Auth0
sonar.auth.saml.providerId=${AUTH0_TENANT_SAML_ISSUER}
sonar.auth.saml.loginUrl=${AUTH0_TENANT_URL}/samlp/${AUTH0_SONARQUBE_CLIENT_ID}
sonar.auth.saml.user.login=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier
sonar.auth.saml.user.name=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name
sonar.auth.saml.user.email=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
sonar.auth.saml.group.name=http://schemas.xmlsoap.org/claims/Group
sonar.auth.saml.certificate.secured=${AUTH0_TENANT_SAML_PEM_AS_PROP%%\\}
END

# Update Dependency Track URL in Auth0 Client
auth0_patch_application_client "${AUTH0_TENANT_URL}" "${AUTH0_MGMT_API_TOKEN}" "${AUTH0_DTRACK_CLIENT_ID}" --data-binary @- <<EOF
{
  "callbacks":[
    "${DTRACK_PUBLIC_URL}/static/oidc-callback.html"
  ],
  "initiate_login_uri": "${DTRACK_PUBLIC_URL}"
}
EOF
