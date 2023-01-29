#!/bin/bash -eu
# Unofficial bash strict mode
set -euo pipefail
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

auth0_get_management_token() {
  # $1 = tenant URL
  # $2 = clientID
  # $3 = clientSecret
  let -r AUTH0_MGMT_OAUTH="${1}/oauth/token"
  let -r AUTH0_MGMT_API="${1}/api/v2"

  # Get Mgmt API Token
  AUTH0_MGMT_API_TOKEN=$(curl --silent --fail --max-time 10 --request POST \
    --url "${AUTH0_MGMT_OAUTH}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-binary @- << EOF | jq -c -e '.access_token'
{
  "client_id": "${2}",
  "client_secret": "${3}",
  "audience": "${AUTH0_MGMT_API}/",
  "grant_type": "client_credentials"
}
EOF
  )
  AUTH0_MGMT_API_TOKEN="${AUTH0_MGMT_API_TOKEN%\"}"
  AUTH0_MGMT_API_TOKEN="${AUTH0_MGMT_API_TOKEN#\"}"
  echo -n "${AUTH0_MGMT_API_TOKEN}"
}

auth0_patch_application_client() {
  # $1 = tenant url, $2 = client ID, $3 = MGMT Token
  let -r AUTH0_MGMT_API="${1}/api/v2"
  let -r CLIENT_ID="${2}"
  let -r MGMT_TOKEN="${3}"
  shift 3

  curl --silent --fail --max-time 10 --output /dev/null --request PATCH \
    --url "${AUTH0_MGMT_API}/clients/${CLIENT_ID}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer ${MGMT_TOKEN}" \
    ${@}
}

source "${script_dir}/.env"

# Auth0...
AUTH0_TENANT_URL="https://dev-bdellegrazie.eu.auth0.com"
AUTH0_TENANT_SAML_ISSUER="urn:dev-bdellegrazie.eu.auth0.com"
AUTH0_OIDC_CUSTOM_CLAIMS_NS="https://dev-bdellegrazie/claims"
AUTH0_SAML_LOGOUT_REDIRECT_URL="https://github.com/bdellegrazie/jenkins-bootstrap"
AUTH0_JENKINS_CLIENT_ID="$(cat ${script_dir}/auth0/Jenkins-Local.id)"
AUTH0_JENKINS_CLIENT_SECRET="$(cat ${script_dir}/auth0/Jenkins-Local.secret)"  # pragma: allowlist secret
AUTH0_JENKINS_SAML_METADATA_URL="${AUTH0_TENANT_URL}/samlp/metadata/${AUTH0_JENKINS_CLIENT_ID}"
AUTH0_JENKINS_SAML_LOGOUT_REDIRECT_URL="${AUTH0_TENANT_URL}/v2/logout?client_id=${AUTH0_JENKINS_CLIENT_ID}&returnTo=$(urlencode ${AUTH0_SAML_LOGOUT_REDIRECT_URL})"
AUTH0_SONARQUBE_CLIENT_ID="$(cat ${script_dir}/auth0/Sonarqube-Local.id)"
#AUTH0_SONARQUBE_CLIENT_SECRET="$(cat ${script_dir}/auth0/Sonarqube-Local.secret)"  # pragma: allowlist secret
AUTH0_SONARQUBE_SAML_METADATA_URL="${AUTH0_TENANT_URL}/samlp/metadata/${AUTH0_SONARQUBE_CLIENT_ID}"
AUTH0_SONARQUBE_SAML_LOGOUT_REDIRECT_URL="${AUTH0_TENANT_URL}/v2/logout?client_id=${AUTH0_SONARQUBE_CLIENT_ID}&returnTo=$(urlencode ${AUTH0_SAML_LOGOUT_REDIRECT_URL})"

cat >> "${script_dir}/.env" <<END
AUTH0_OIDC_BASE_URL="${AUTH0_TENANT_URL}"
AUTH0_OIDC_CUSTOM_CLAIMS_NS="${AUTH0_OIDC_CUSTOM_CLAIMS_NS}"
END

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
curl --silent --fail --max-time 10 --output /dev/null --request PATCH \
  --url "${AUTH0_MGMT_API}/clients/${AUTH0_SONARQUBE_CLIENT_ID}" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer ${AUTH0_MGMT_API_TOKEN}" \
  --data-binary @- <<EOF
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
AUTH0_TENANT_SAML_PEM_AS_PROP="$(cat "${script_dir}/auth0/dev-bdellegrazie.pem.secret" | tr -d '\r' | sed -E -e 's|$|\\|g')"
cat > "${script_dir}/sonarqube/auth/saml.properties" <<END

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
