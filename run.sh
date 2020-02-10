#!/bin/bash -eu
# Unofficial bash strict mode
set -o pipefail
IFS=$'\n\t'

_UID=$(id -u)
_GID=$(id -g)
_GID_DOCKER=$(getent group docker | awk -F: '{print $3}')

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Logging
mkdir -p ${script_dir}/home
cat > ${script_dir}/home/logging.properties <<EOF
handlers=java.util.logging.ConsoleHandler
jenkins.level=INFO
java.util.logging.ConsoleHandler.level=INFO
# Uncomment to debug SAML
#java.util.logging.ConsoleHandler.level=FINEST
#org.jenkinsci.plugins.saml.level=FINEST
#org.pac4j.level=FINE
EOF

# Pre-generate ssh known_host keys
mkdir -p ${script_dir}/home/.ssh
chmod 0700 ${script_dir}/home/.ssh
ssh-keyscan -H github.com > ${script_dir}/home/.ssh/known_hosts 2> /dev/null
chmod 0600 ${script_dir}/home/.ssh/known_hosts

# Options
JAVA_OPTS="-Djava.util.logging.config.file=/var/jenkins_home/logging.properties -Djenkins.install.runSetupWizard=false"
JENKINS_OPTS=--httpPort=8081

source ${script_dir}/.env

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
  -e AUTH0_SAML_METADATA_URL="${AUTH0_SAML_METADATA_URL}" \
  -e AUTH0_SAML_LOGOUT_URL="${AUTH0_SAML_LOGOUT_URL}" \
  --name jenkins-bdg \
  bdg/jenkins:latest
