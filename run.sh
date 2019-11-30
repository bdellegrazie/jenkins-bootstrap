#!/bin/bash -eu
# Unofficial bash strict mode
set -o pipefail
IFS=$'\n\t'

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


_UID=$(id -u)
_GID=$(id -g)
_GID_DOCKER=$(getent group docker | awk -F: '{print $3}')

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NGROK_API="http://127.0.0.1:4040/api"
NGROK_TUNNEL=jenkins

# Start ngrok as a temporary service
#systemd-run --user --unit=ngrok ngrok start --config $HOME/.ngrok2/ngrok.yml --none --log stdout --log-format term
#systemd-run --user --unit=ngrok ngrok start --config $HOME/.ngrok2/ngrok.yml --config ${script_dir}}/ngrok.yml --all --log stdout --log-format term

# Does the tunnel exist already?
set +e
JENKINS_PUBLIC_URL=$(curl --silent --fail --max-time 10 \
  --url "${NGROK_API}/tunnels/${NGROK_TUNNEL}" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' | jq -c -e '.public_url')
TUNNEL_RC=$?
set -e

if [[ $TUNNEL_RC -ne 0 ]]; then
  JENKINS_PUBLIC_URL=$(curl --silent --fail --max-time 10 --request POST \
    --url "${NGROK_API}/tunnels" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --data-binary @- << EOF |  jq -c -e '.public_url'
{
  "name": "${NGROK_TUNNEL}",
  "proto": "http",
  "addr": "8081"
}
EOF
)
fi

JENKINS_PUBLIC_URL="${JENKINS_PUBLIC_URL%\"}"
JENKINS_PUBLIC_URL="${JENKINS_PUBLIC_URL#\"}"
JENKINS_SAML_CALLBACK_URL="${JENKINS_PUBLIC_URL}/securityRealm/finishLogin"
JENKINS_LOGIN_URL="${JENKINS_PUBLIC_URL}/login"
JENKINS_LOGOUT_URL="${JENKINS_PUBLIC_URL}/logout"
echo "Jenkins PL: $JENKINS_PUBLIC_URL"

# Auth0... Jenkins Local Deploy Client
AUTH0_JENKINS_CLIENT_ID="$(cat ${script_dir}/auth0/Jenkins-Local.id)"
AUTH0_JENKINS_CLIENT_SECRET="$(cat ${script_dir}/auth0/Jenkins-Local.secret)"  # pragma: allowlist secret
AUTH0_TENANT='dev-bdellegrazie'
AUTH0_DOMAIN='eu.auth0.com'
AUTH0_BASE_URL="https://${AUTH0_TENANT}.${AUTH0_DOMAIN}"
AUTH0_MGMT_OAUTH="${AUTH0_BASE_URL}/oauth/token"
AUTH0_MGMT_API="${AUTH0_BASE_URL}/api/v2"
# Calculate Jenkins IdP Metadata URL
AUTH0_IDP_METADATA_URL="${AUTH0_BASE_URL}/samlp/metadata/${AUTH0_JENKINS_CLIENT_ID}"
AUTH0_IDP_LOGOUT_REDIRECT_URL="https://github.com/bdellegrazie/jenkins-bootstrap"
AUTH0_IDP_LOGOUT_URL="${AUTH0_BASE_URL}/v2/logout?client_id=${AUTH0_JENKINS_CLIENT_ID}&returnTo=$(urlencode ${AUTH0_IDP_LOGOUT_REDIRECT_URL})"

echo "IdP Metadata URL: $AUTH0_IDP_METADATA_URL"
echo "IdP Logout URL: $AUTH0_IDP_LOGOUT_URL"

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
  --data-binary @- << EOF
{
  "addons": {
    "samlp": {
      "logout": {
        "callback": "${JENKINS_LOGOUT_URL}"
      }
    }
  },
  "allowed_logout_urls": [
    "https://github.com/bdellegrazie/jenkins-bootstrap"
  ],
  "callbacks":[
    "${JENKINS_SAML_CALLBACK_URL}"
  ],
  "initiate_login_uri": "${JENKINS_LOGIN_URL}",
  "logo_uri": "https://jenkins.io/images/logos/jenkins/jenkins.svg"
}
EOF

echo "Auth0 Jenkins-Local updated successfully!"

export JENKINS_PUBLIC_URL JENKINS_LOGOUT_URL AUTH0_IDP_METADATA_URL AUTH0_IDP_LOGOUT_URL

# Logging
mkdir -p ${script_dir}/home
cat > ${script_dir}/home/log.properties <<EOF
handlers=java.util.logging.ConsoleHandler
jenkins.level=INFO
java.util.logging.ConsoleHandler.level=INFO
EOF

# Pre-generate ssh known_host keys
mkdir -p ${script_dir}/home/.ssh
chmod 0700 ${script_dir}/home/.ssh
ssh-keyscan -H github.com > ${script_dir}/home/.ssh/known_hosts 2> /dev/null
chmod 0600 ${script_dir}/home/.ssh/known_hosts

# Options
JAVA_OPTS="-Djava.util.logging.config.file=/var/jenkins_home/log.properties -Djenkins.install.runSetupWizard=false"
JENKINS_OPTS=--httpPort=8081

# Run
docker run \
  --rm \
  -p 8081:8081 \
  -p 50001:50001 \
  -u ${_UID}:${_GID} \
  --group-add ${_GID_DOCKER} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${script_dir}/home:/var/jenkins_home \
  -v ${script_dir}/casc_configs:/var/jenkins_home/casc_configs \
  -e BOOTSTRAP_GIT_REPO="https://github.com/bdellegrazie/jenkins-bootstrap.git" \
  -e BOOTSTRAP_SSH_DEPLOY_KEY="$(cat ~/.ssh/jenkins-bootstrap-deploy.key)" \
  -e TRY_UPGRADE_IF_NO_MARKER=true \
  -e CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/ \
  -e JAVA_OPTS="${JAVA_OPTS}" \
  -e JENKINS_OPTS="${JENKINS_OPTS}" \
  -e JENKINS_PUBLIC_URL="${JENKINS_PUBLIC_URL}" \
  -e JENKINS_LOGIN_URL="${JENKINS_LOGIN_URL}" \
  -e JENKINS_LOGOUT_URL="${JENKINS_LOGOUT_URL}" \
  -e JENKINS_SAML_CALLBACK_URL="${JENKINS_SAML_CALLBACK_URL}" \
  -e AUTH0_IDP_METADATA_URL="${AUTH0_IDP_METADATA_URL}" \
  -e AUTH0_IDP_LOGOUT_URL="${AUTH0_IDP_LOGOUT_URL}" \
  --name jenkins-bdg \
  bdg/jenkins:latest