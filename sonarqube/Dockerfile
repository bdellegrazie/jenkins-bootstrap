FROM quay.io/prometheuscommunity/elasticsearch-exporter:v1.5.0 as exporter

FROM sonarqube:lts

ARG BRANCH_PLUGIN_VERSION=1.8.3
ARG OIDC_PLUGIN_VERSION=2.1.1
ARG JMX_EXPORTER_VERSION=0.17.2

RUN wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_PLUGIN_VERSION}.jar\
    https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${BRANCH_PLUGIN_VERSION}/sonarqube-community-branch-plugin-${BRANCH_PLUGIN_VERSION}.jar &&\
  wget -c -q -T 30 -O /opt/sonarqube/extensions/plugins/sonar-auth-oidc-plugin-${OIDC_PLUGIN_VERSION}.jar\
    https://github.com/vaulttec/sonar-auth-oidc/releases/download/v${OIDC_PLUGIN_VERSION}/sonar-auth-oidc-plugin-${OIDC_PLUGIN_VERSION}.jar &&\
  chown sonarqube:sonarqube /opt/sonarqube/extensions/plugins/*.jar &&\
  mkdir -p /opt/jmx_exporter &&\
  wget -c -q -T 30 -O /opt/jmx_exporter/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar\
    https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar &&\
  ln -sf /opt/jmx_exporter/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar /opt/jmx_exporter/jmx_prometheus_javaagent.jar

COPY --chown=root:root --from=exporter /bin/elasticsearch_exporter /bin/elasticsearch_exporter
COPY --chown=root:root monitor.yaml /opt/jmx_exporter/monitor.yaml
COPY --chown=sonarqube:sonarqube sonar.properties /opt/sonarqube/conf/sonar.properties

COPY --chown=sonarqube:sonarqube 00-run.sh /opt/sonarqube/bin/00-run.sh
RUN chmod 0755 /opt/sonarqube/bin/00-run.sh

ENTRYPOINT [ "/opt/sonarqube/bin/00-run.sh" ]
