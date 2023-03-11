#!/bin/bash -eu
# Unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Prepare sonarqube configuration
cat "${script_dir}/sonarqube/sonar.properties" "${script_dir}/sonarqube/auth/saml.properties" > "${script_dir}/sonarqube/auth/sonar.properties"

sudo sysctl -w vm.max_map_count=262144
