#!/bin/sh

set -eu
IFS=$'\n\t'

CONFIG_DIR="/etc/blackbox_exporter"
CONFIG_TGT="/tmp/config.yml"
SECRET_LIST="${CONFIG_DIR}/secrets.list"
SECRET_DIR="/run/secrets"

cp -a "${CONFIG_DIR}/config.yml" "${CONFIG_TGT}"

if [ -r "${SECRET_LIST}" ]; then
  while read SECRET ; do
    if [ -n "${SECRET}" ]; then
      if [ -f "${SECRET_DIR}/${SECRET}" ]; then
        echo "Replacing @${SECRET}@ in ${CONFIG_TGT}"
        VALUE="$(cat "${SECRET_DIR}/${SECRET}")"
        sed -i -E "s/@${SECRET}@/${VALUE}/g" "${CONFIG_TGT}"
      else
        echo "${SECRET_DIR}/${SECRET} not found, skipping"
      fi
    fi
  done < "${SECRET_LIST}"
else
  echo "${SECRET_LIST} not found, skipping all"
fi

exec /bin/blackbox_exporter "$@"
