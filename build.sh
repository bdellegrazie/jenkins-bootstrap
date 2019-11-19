#!/bin/bash
docker pull jenkins/jenkins:lts-alpine
docker build -t bdg/jenkins:latest .
