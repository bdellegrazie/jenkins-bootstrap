# https://github.com/jenkinsci/docker/blob/master/Dockerfile-slim
FROM jenkins/jenkins:lts-slim-jdk17 as base

ARG BUILD_VERSION=0
LABEL name="bdellegrazie/jenkins" vendor="brett.dellegrazie@gmail.com" version="${JENKINS_VERSION}-${BUILD_VERSION}"
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt && \
  rm -rf "${HOME}/.cache/jenkins-plugin-management-cli" "${PWD}/.cache/jenkins-plugin-management-cli"
RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

FROM base as jenkins

USER root
ARG user=jenkins
ARG DOCKER_GROUP_NAME=docker
ARG DOCKER_GROUP_GID=998
RUN addgroup --system --gid ${DOCKER_GROUP_GID} ${DOCKER_GROUP_NAME} \
  && adduser ${user} ${DOCKER_GROUP_NAME}

RUN mkdir -p /builds /workspaces && chown ${user}:${DOCKER_GROUP_GID} /builds /workspaces

USER ${user}

COPY logging.properties.override /usr/share/jenkins/ref/

# Core configuration
ENV JENKINS_JAVA_OPTS -Djava.util.logging.config.file=/var/jenkins_home/logging.properties\
 -Djenkins.model.Jenkins.buildsDir='/builds/${ITEM_FULL_NAME}'\
 -Djenkins.model.Jenkins.workspacesDir='/workspaces/${ITEM_FULL_NAME}'
ENV JENKINS_OPTS  --httpPort=8080
ENV JENKINS_SLAVE_AGENT_PORT -1

# Public URL without a trailing slash
ARG JENKINS_PUBLIC_URL=http://localhost:8080
ENV JENKINS_PUBLIC_URL=${JENKINS_PUBLIC_URL}

# Minutes between refresh of the Metadata
#ARG JENKINS_SAML_METADATA_REFRESH_MIN=15
#ENV JENKINS_SAML_METADATA_REFRESH_MIN=${JENKINS_SAML_METADATA_REFRESH_MIN}

# Jenkins Session lifetime (default 10 hours)
#ARG JENKINS_SAML_SESSION_LIFETIME_SEC=36000
#ENV JENKINS_SAML_SESSION_LIFETIME_SEC=${JENKINS_SAML_SESSION_LIFETIME_SEC}

# Auth0 Application Metadata URL
#ARG AUTH0_SAML_METADATA_URL=https://dev-bdellegrazie.eu.auth0.com/samlp/metadata/f4NPjI7TQwpbS4nPJ0ST4CRXZnWCero5
#ENV AUTH0_SAML_METADATA_URL=${AUTH0_SAML_METADATA_URL}

# Full Logout URL (add '&federated' to logout of IdP as well)
#ARG AUTH0_JENKINS_SAML_LOGOUT_URL=https://dev-bdellegrazie.eu.auth0.com/v2/logout?client_id=f4NPjI7TQwpbS4nPJ0ST4CRXZnWCero5&returnTo=https%3A%2F%2Fgithub.com%2Fbdellegrazie%2Fjenkins-bootstrap
#ENV AUTH0_JENKINS_SAML_LOGOUT_URL=${AUTH0_JENKINS_SAML_LOGOUT_URL}

# OIDC Well-Known metadata URL
ARG AUTH0_OIDC_BASE_URL=https://dev-bdellegrazie.eu.auth0.com
ENV AUTH0_OIDC_BASE_URL=${AUTH0_OIDC_BASE_URL}

VOLUME ["/builds", "/workspaces"]
