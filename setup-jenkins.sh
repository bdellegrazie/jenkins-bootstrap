#!/bin/bash -eu
# Unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cat >> "${script_dir}/.env" <<END
DOCKER_GROUP_GID=$(getent group docker | awk -F: '{print $3}')
END
