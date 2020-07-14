#!/bin/bash -eu
# Unofficial bash strict mode
set -o pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cat >> "${script_dir}/.env" <<END
JAVA_OPTS='-Djava.util.logging.config.file=/var/jenkins_home/logging.properties -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.buildsDir=/build/\${ITEM_FULL_NAME} -Djenkins.model.Jenkins.workspacesDir=/workspace/\${ITEM_FULL_NAME}'
JENKINS_OPTS="--httpPort=8080"
JENKINS_SLAVE_AGENT_PORT="-1"
DOCKER_GROUP_GID=$(getent group docker | awk -F: '{print $3}')
END
