#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function usage() {
  cat >&2 <<END
Usage:
  ${0} <BASE_URL> <API_KEY>

Where:
  <BASE_URL>: Base URL of Dependency Track
  <API_KEY>: API Key created via UI
END
  exit 1
}

[[ $# -eq 2 ]] || usage

BASE_URL="${1}/api"
API_KEY="${2}"
TIMEOUT=10

function _dtrack_api() {
  local -r _method="${1}"
  local -r _request="${2}"
  shift 2
  local _option=()
  case "${_method^}" in
    GET) _option=("--get") ;;
    HEAD) _option=("--head") ;;
    POST) _option=("--post301" "--post302" "--data" "") ;;
    *) _option=("--request" "${_method^}") ;;
  esac

  curl -fsSL -m ${TIMEOUT} \
    "${_option[@]}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "X-Api-Key: ${API_KEY}" \
    --url "${BASE_URL}/${_request}" \
    ${@}
}

function dtrack_permission_get_all() {
  _dtrack_api GET v1/permission
}

function dtrack_permission_team_add() {
  local -r _permission="${1}"
  local -r _team_uuid="${2}"
  _dtrack_api POST "v1/permission/${_permission}/team/${_team_uuid}"
}

function dtrack_team_create() {
  local -r _name="${1}"
  _dtrack_api PUT v1/team --data-binary @- <<EOF
{
  "name": "${1}"
}
EOF
}

function dtrack_team_get_all() {
  _dtrack_api GET v1/team
}

function dtrack_team_get_by_uuid() {
  local -r _uuid="${1}"
  _dtrack_api GET "v1/team/${_uuid}"
}

function dtrack_team_exists_by_name() {
  local -r _api="${1}"
  local -r _name="${2}"
  echo "${_api}" | jq -e --arg name "${_name}" 'map(.name) | index($name)' > /dev/null
}

function dtrack_team_get_uuid_of() {
  local -r _api="${1}"
  local -r _team="${2}"
  echo "${_api}" | jq -e -r --arg name "${_team}" '.[] | select(.name == $name) | .uuid'
}

function dtrack_team_get_first_api_key() {
  local -r _api="${1}"
  local -r _team="${2}"
  echo "${_api}" | jq -e -r --arg name "${_team}" '.[] | select(.name == $name) .apiKeys | map(.key) | first'
}

function dtrack_team_oidc_mapping_get_all() {
  local -r _api="${1}"
  local -r _team="${2}"
  echo "${_api}" | jq -e -r --arg name "${_team}" '.[] | select(.name == $name) | .mappedOidcGroups'
}

function dtrack_team_oidc_mapping_exists_by_uuid() {
  local -r _api="${1}"
  local -r _uuid="${2}"
  echo "${_api}" | jq -e --arg uuid "${_uuid}" 'map(.group.uuid) | index($uuid)' > /dev/null
}

function dtrack_team_permissions_get_all() {
  local -r _api="${1}"
  local -r _team="${2}"
  echo "${_api}" | jq -e -r --arg name "${_team}" '.[] | select(.name == $name) | .permissions | map(.name)'
}

function dtrack_team_permissions_exist_by_name() {
  local -r _api="${1}"
  local -r _name="${2}"
  echo "${_api}" | jq -e --arg name "${_name}" 'index($name)' > /dev/null
}

function dtrack_oidc_group_get_all() {
  _dtrack_api GET v1/oidc/group
}

function dtrack_oidc_group_get() {
  local -r _api="${1}"
  local -r _name="${2}"
  echo "${_api}" | jq -e -r --arg name "${_name}" '.[] | select(.name == $name)'
}

function dtrack_oidc_group_get_uuid_of() {
  local -r _api="${1}"
  local -r _name="${2}"
  echo "${_api}" | jq -e -r --arg name "${_name}" '.[] | select(.name == $name) | .uuid'
}

function dtrack_oidc_group_exists_by_name() {
  local -r _api="${1}"
  local -r _name="${2}"
  echo "${_api}" | jq -e --arg name "${_name}" 'map(.name) | index($name)' > /dev/null
}

function dtrack_oidc_group_create() {
  local -r _name="${1}"
  _dtrack_api PUT v1/oidc/group --data-binary @- <<EOF
{
  "name": "${_name}"
}
EOF
}

function dtrack_oidc_mapping_create() {
  local -r _team="${1}"
  local -r _group="${2}"
  _dtrack_api PUT v1/oidc/mapping --data-binary @- <<EOF
{
  "team": "${_team}",
  "group": "${_group}"
}
EOF
}

function dtrack_oidc_group_ensure_create() {
  local -r _name="${1}"
  local -r _groups=$(dtrack_oidc_group_get_all)

  if ! dtrack_oidc_group_exists_by_name "${_groups}" "${_name}" ; then
    echo "Creating OIDC Group \"${_name}\""
    dtrack_oidc_group_create "${_name}"
  fi
}

function dtrack_team_ensure_create() {
  local -r _name="${1}"
  local -r _teams=$(dtrack_team_get_all)

  if ! dtrack_team_exists_by_name "${_teams}" "${_name}" ; then
    echo "Creating Team \"${_name}\""
    dtrack_team_create "${_name}"
  fi
}


# Create Administrators OIDC Group if it doesn't exist
dtrack_oidc_group_ensure_create "Administrators"

# All OIDC groups
declare _oidc_groups=$(dtrack_oidc_group_get_all)
# UUID of OIDC Administrators Group
declare -r administrators_oidc_group_uuid=$(dtrack_oidc_group_get_uuid_of "${_oidc_groups}" "Administrators")

dtrack_team_ensure_create "Monitor"

# All teams
declare _teams=$(dtrack_team_get_all)

# UUID of Administrators Team
declare -r administrators_team_uuid=$(dtrack_team_get_uuid_of "${_teams}" "Administrators")

# Create Mapping Administrators OIDC Group -> Administrators Team
declare administrators_team_oidc_mappings=$(dtrack_team_oidc_mapping_get_all "${_teams}" "Administrators")
if ! dtrack_team_oidc_mapping_exists_by_uuid "${administrators_team_oidc_mappings}" "${administrators_oidc_group_uuid}" ; then
  echo "Creating OIDC Group ($${administrators_oidc_group_uuid}) mapping to Team (${administrators_team_uuid})"
  dtrack_oidc_mapping_create "${administrators_team_uuid}" "${administrators_oidc_group_uuid}"
  _teams=$(dtrack_team_get_all)
fi

# All permissions
declare -r _permissions=$(dtrack_permission_get_all)
# UUID of Automation Team
declare -r automation_team_uuid=$(dtrack_team_get_uuid_of "${_teams}" "Automation")

# Extend permission of Automation Team by those suggested for the Jenkins DependencyTrack plugin
# https://plugins.jenkins.io/dependency-track/#plugin-content-permission-overview
declare automation_team_permissions=$(dtrack_team_permissions_get_all "${_teams}" "Automation" || echo "[]")
for _permission in "BOM_UPLOAD" "PORTFOLIO_MANAGEMENT" "PROJECT_CREATION_UPLOAD" "VIEW_PORTFOLIO" "VIEW_VULNERABILITY" "VULNERABILITY_ANALYSIS" ; do
  if ! dtrack_team_permissions_exist_by_name "${automation_team_permissions}" "${_permission}" ; then
    echo "adding permission \"${_permission}\" to team (${automation_team_uuid})"
    dtrack_permission_team_add "${_permission}" "${automation_team_uuid}"
  fi
done

declare -r monitor_team_uuid=$(dtrack_team_get_uuid_of "${_teams}" "Monitor")
# Extend permission of Monitor Team by those required by the Dependency Track Exporter
# https://plugins.jenkins.io/dependency-track/#plugin-content-permission-overview
declare monitor_team_permissions=$(dtrack_team_permissions_get_all "${_teams}" "Monitor" || echo "[]")
for _permission in "VIEW_POLICY_VIOLATION" "VIEW_PORTFOLIO" ; do
  if ! dtrack_team_permissions_exist_by_name "${monitor_team_permissions}" "${_permission}" ; then
    echo "adding permission \"${_permission}\" to team (${monitor_team_uuid})"
    dtrack_permission_team_add "${_permission}" "${monitor_team_uuid}"
  fi
done

echo "Updating Jenkins DependencyTrack API Key Secret"
echo -n "$(dtrack_team_get_first_api_key "${_teams}" "Automation")" > "${script_dir}/secrets/dtrack_volatile.secret"

echo "Updating Dtrack Monitor API Key Secret"
echo -n "DEPENDENCY_TRACK_API_KEY=$(dtrack_team_get_first_api_key "${_teams}" "Monitor")" > "${script_dir}/secrets/dtrack_monitor_volatile.secret"
