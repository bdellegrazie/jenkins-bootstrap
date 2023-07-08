#!/usr/bin/env bash
docker compose -f compose.ci.yaml -f compose.dependency-track.yaml -f compose.monitoring.yaml "${@}"
