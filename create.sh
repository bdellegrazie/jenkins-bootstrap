#!/bin/bash
_UID=$(id -u)
_GID=$(id -g)
_GID_DOCKER=$(getent group docker | awk -F: '{print $3}')

# Logging
mkdir -p ${PWD}/home
cat > ${PWD}/home/log.properties <<EOF
handlers=java.util.logging.ConsoleHandler
jenkins.level=INFO
java.util.logging.ConsoleHandler.level=INFO
EOF

# Options
JAVA_OPTS="-Djava.util.logging.config.file=/var/jenkins_home/log.properties -Djenkins.install.runSetupWizard=false"
JENKINS_OPTS=--httpPort=8081

# Run
docker run \
  -p 8081:8081 \
  -p 50000:50000 \
  -p 50001:50001 \
  -u ${_UID}:${_GID} \
  --group-add ${_GID_DOCKER} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${PWD}/home:/var/jenkins_home \
  -v ${PWD}/init.groovy.d:/var/jenkins_home/init.groovy.d \
  -v ${PWD}/casc_configs:/var/jenkins_home/casc_configs \
  -e TRY_UPGRADE_IF_NO_MARKER=true \
  -e CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/ \
  -e JAVA_OPTS="${JAVA_OPTS}" \
  -e JENKINS_OPTS="${JENKINS_OPTS}" \
  --name jenkins-bdg \
  bdg/jenkins:latest
