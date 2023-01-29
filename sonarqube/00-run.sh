#!/usr/bin/env bash

set -euo pipefail

if [[ -r /run/secrets/sonar_jdbc_username ]]; then
  export SONAR_JDBC_USERNAME="$(< /run/secrets/sonar_jdbc_username)"
fi

if [[ -r /run/secrets/sonar_jdbc_password ]]; then
  export SONAR_JDBC_PASSWORD="$(< /run/secrets/sonar_jdbc_password)"
fi

if [[ -r /run/secrets/sonar_web_systempasscode ]]; then
  export SONAR_WEB_SYSTEMPASSCODE="$(< /run/secrets/sonar_web_systempasscode)"
fi

if [[ -r /run/secrets/sonar_auth_jwtbase64hs256secret ]]; then
  export SONAR_AUTH_JWTBASE64HS256SECRET="$(< /run/secrets/sonar_auth_jwtbase64hs256secret)"
fi

# Handle SAML authentication by concatenating generated properties
# Environment variables don't work!
if [[ -r /etc/sonarqube/saml.properties ]]; then
  sed -i -E -e '/#SAML-AUTH-BEGIN/q' /opt/sonarqube/conf/sonar.properties
  cat /etc/sonarqube/saml.properties >> /opt/sonarqube/conf/sonar.properties
fi

# Necessary because sonarqube community doesn't support binding search to a specific IP
/bin/elasticsearch_exporter --es.uri='http://127.0.0.1:9001' &

exec /opt/sonarqube/bin/run.sh $@
