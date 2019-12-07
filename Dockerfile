# https://github.com/jenkinsci/docker/blob/master/Dockerfile-alpine
FROM jenkins/jenkins:lts-alpine

ARG BUILD_VERSION=0
LABEL name="bdellegrazie/jenkins" vendor="brett.dellegrazie@gmail.com" version="${JENKINS_VERSION}-${BUILD_VERSION}"
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

# Public URL without a trailing slash
ARG JENKINS_PUBLIC_URL=http://localhost:8080
ENV JENKINS_PUBLIC_URL=${JENKINS_PUBLIC_URL}

# Minutes between refresh of the Metadata
ARG JENKINS_SAML_METADATA_REFRESH_MIN=15
ENV JENKINS_SAML_METADATA_REFRESH_MIN=${JENKINS_SAML_METADATA_REFRESH_MIN}

# Jenkins Session lifetime (default 10 hours)
ARG JENKINS_SAML_SESSION_LIFETIME_SEC=36000
ENV JENKINS_SAML_SESSION_LIFETIME_SEC=${JENKINS_SAML_SESSION_LIFETIME_SEC}

# Auth0 Tenant (default is mine)
ARG AUTH0_TENANT_URL=https://dev-bdellegrazie.eu.auth0.com
ENV AUTH0_TENANT_URL=${AUTH0_TENANT_URL}

# Auth0 Jenkins Client Application ID (default is mine)
ARG AUTH0_JENKINS_CLIENT_ID=f4NPjI7TQwpbS4nPJ0ST4CRXZnWCero5
ENV AUTH0_JENKINS_CLIENT_ID=${AUTH0_JENKINS_CLIENT_ID}

# Logout URL, url-encoded
ARG LOGOUT_URL_ENCODED=https%3A%2F%2Fgithub.com%2Fbdellegrazie%2Fjenkins-bootstrap
ENV LOGOUT_URL_ENCODED=${LOGOUT_URL_ENCODED}

# Calculated values
# Auth0 Application Metadata URL
ENV AUTH0_SAML_METADATA_URL=${AUTH0_TENANT_URL}/samlp/metadata/${AUTH0_JENKINS_CLIENT_ID}

# Full Logout URL (add '&federated' to logout of IdP as well)
ENV AUTH0_SAML_LOGOUT_URL=${AUTH0_TENANT_URL}/v2/logout?client_id=${AUTH0_JENKINS_CLIENT_ID}&returnTo=${LOGOUT_URL_ENCODED}
