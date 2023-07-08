#!/bin/bash -eu
# Unofficial bash strict mode
set -euo pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NGROK_API="http://127.0.0.1:4040/api"

function ngrok_is_active_linux() {
  set +e
  systemctl --user is-active --quiet ngrok.service
  _rc=$?
  set -e
  return "${_rc}"
}

function ngrok_start_linux() {
  local _rc=0
  if ! ngrok_is_active_linux ; then
    set +e
    systemd-run --user --unit=ngrok ngrok start --config "${XDG_CONFIG_HOME:=${HOME}/.config}/ngrok/ngrok.yml" --none --log stdout --log-format term
    _rc=$?
    set -e
    sleep 5
  fi
  if [[ $_rc -eq 0 ]] ; then
    echo "Ngrok is started "
  fi
  return "${_rc}"
}

function ngrok_stop_linux() {
  local _rc=0
  if ngrok_is_active_linux ; then
    set +e
    systemctl --user stop ngrok.service
    _rc=$?
    set -e
  fi
  return "${_rc}"
}

function ngrok_tunnel() {
  local _name=${1:?Name of tunnel (required)}
  local _addr=${2:?Target of tunnel (required)}
  local _proto=${3:-http}
  declare -gnx _export="${4:-${1^^}}_PUBLIC_URL"
  local _rc=0

  # Does the tunnel exist already?
  set +e
  _export=$(curl --silent --retry 3 --retry-delay 2 --fail --max-time 10 \
    --url "${NGROK_API}/tunnels/${_name}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' | jq -c -e '.public_url')
  _rc=$?
  set -e

  # Create if not exist
  if [[ $_rc -ne 0 ]]; then
    _export=$(curl --silent --fail --max-time 10 \
      --url "${NGROK_API}/tunnels" \
      --header 'Content-Type: application/json' \
      --header 'Accept: application/json' \
      --data-binary @- << EOF |  jq -c -e '.public_url'
{
  "name": "${_name}",
  "proto": "${_proto}",
  "addr": "${_addr}",
  "metadata": "${_name} Service"
}
EOF
    )
  fi

  # Strip quotes
  _export="${_export%\"}"
  _export="${_export#\"}"
}

ngrok_start_linux
ngrok_tunnel jenkins 8080
ngrok_tunnel sonarqube 9000
ngrok_tunnel dtrack 8090

cat "${script_dir}/.env.ci" "${script_dir}/.env.monitoring" "${script_dir}/.env.dependency-track" > "${script_dir}/.env"
cat >> "${script_dir}/.env" <<END
JENKINS_PUBLIC_URL=${JENKINS_PUBLIC_URL}
SONARQUBE_PUBLIC_URL=${SONARQUBE_PUBLIC_URL}
DTRACK_PUBLIC_URL=${DTRACK_PUBLIC_URL}
END
