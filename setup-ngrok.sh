#!/bin/bash -eu
# Unofficial bash strict mode
set -o pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NGROK_API="http://127.0.0.1:4040/api"
NGROK_TUNNEL=jenkins

# Start ngrok as a temporary service
set +e
systemctl --user is-active --quiet ngrok.service
NGROK_RC=$?
set -e
if [[ $NGROK_RC -ne 0 ]] ; then
  systemd-run --user --unit=ngrok ngrok start --config $HOME/.ngrok2/ngrok.yml --none --log stdout --log-format term
  sleep 5
fi

# Does the tunnel exist already?
set +e
JENKINS_PUBLIC_URL=$(curl --silent --retry 3 --retry-delay 2 --fail --max-time 10 \
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

cat > "${script_dir}/.env" <<END
JENKINS_PUBLIC_URL=${JENKINS_PUBLIC_URL}
END
