#!/usr/bin/env bash
# Unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cat >> "${script_dir}/.env" <<END
ALPINE_DATABASE_PASSWORD=$(< "${script_dir}/db/dtrack.secret")
ALPINE_DATABASE_USERNAME=dtrack
ALPINE_METRICS_AUTH_USERNAME=monitor
ALPINE_METRICS_AUTH_PASSWORD=$(< "${script_dir}/db/monitor.secret")
END
