#!/bin/bash
docker pull jenkinsci/blueocean:latest
docker build -t bdg/jenkins:latest .
