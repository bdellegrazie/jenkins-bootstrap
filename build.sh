#!/bin/bash -eu
set -o pipefail
docker pull jenkins/jenkins:lts-alpine
docker build -t bdg/jenkins:latest .
