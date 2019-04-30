FROM jenkins/jenkins:lts
LABEL name="bdellegrazie/jenkins" vendor="brett.dellegrazie@gmail.com" version="${JENKINS_VERSION}-0"
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
