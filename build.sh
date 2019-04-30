#!/bin/bash
docker pull jenkins/jenkins:lts
docker build -t bdg/jenkins:latest .
