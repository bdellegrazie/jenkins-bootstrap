FROM quay.io/prometheuscommunity/elasticsearch-exporter:v1.6.0 as exporter

FROM sonarqube:9.9-community

ARG JMX_EXPORTER_VERSION=0.18.0
# Change branch plugin version in sonar.properties too
ARG BRANCH_PLUGIN_VERSION=1.14.0
ARG CHECKSTYLE_PLUGIN_VERSION=10.12.3
ARG DEPENDENCY_CHECK_PLUGIN_VERSION=4.0.0
ARG FINDBUGS_PLUGIN_VERSION=4.2.4
ARG PMD_PLUGIN_VERSION=3.4.0
ARG SHELLCHECK_PLUGIN_VERSION=2.5.0

USER root
RUN \
 wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_PLUGIN_VERSION}.jar\
  https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${BRANCH_PLUGIN_VERSION}/sonarqube-community-branch-plugin-${BRANCH_PLUGIN_VERSION}.jar &&\
 wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/checkstyle-sonar-plugin-${CHECKSTYLE_PLUGIN_VERSION}.jar\
  https://github.com/checkstyle/sonar-checkstyle/releases/download/${CHECKSTYLE_PLUGIN_VERSION}/checkstyle-sonar-plugin-${CHECKSTYLE_PLUGIN_VERSION}.jar &&\
 wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/sonar-dependency-check-plugin-${DEPENDENCY_CHECK_PLUGIN_VERSION}.jar\
  https://github.com/dependency-check/dependency-check-sonar-plugin/releases/download/${DEPENDENCY_CHECK_PLUGIN_VERSION}/sonar-dependency-check-plugin-${DEPENDENCY_CHECK_PLUGIN_VERSION}.jar &&\
 wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/sonar-findbugs-plugin-${FINDBUGS_PLUGIN_VERSION}.jar\
  https://github.com/spotbugs/sonar-findbugs/releases/download/${FINDBUGS_PLUGIN_VERSION}/sonar-findbugs-plugin-${FINDBUGS_PLUGIN_VERSION}.jar &&\
 wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/sonar-pmd-plugin-${PMD_PLUGIN_VERSION}.jar\
  https://github.com/jborgers/sonar-pmd/releases/download/${PMD_PLUGIN_VERSION}/sonar-pmd-plugin-${PMD_PLUGIN_VERSION}.jar &&\
 wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/sonar-shellcheck-plugin-${SHELLCHECK_PLUGIN_VERSION}.jar\
  https://github.com/sbaudoin/sonar-shellcheck/releases/download/v${SHELLCHECK_PLUGIN_VERSION}/sonar-shellcheck-plugin-${SHELLCHECK_PLUGIN_VERSION}.jar &&\
 chown sonarqube:sonarqube /opt/sonarqube/extensions/plugins/*.jar &&\
 mkdir -p /opt/jmx_exporter &&\
 wget -c -q -T 30 -O /opt/jmx_exporter/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar\
  https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar &&\
 ln -sf /opt/jmx_exporter/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar /opt/jmx_exporter/jmx_prometheus_javaagent.jar

COPY --chown=root:root --from=exporter /bin/elasticsearch_exporter /bin/elasticsearch_exporter
COPY --chown=root:root monitor.yaml /opt/jmx_exporter/monitor.yaml
COPY --chown=sonarqube:sonarqube 00-entrypoint.sh /opt/sonarqube/docker/00-entrypoint.sh
RUN chmod 0755 /opt/sonarqube/docker/00-entrypoint.sh

USER sonarqube

ENTRYPOINT [ "/opt/sonarqube/docker/00-entrypoint.sh" ]
