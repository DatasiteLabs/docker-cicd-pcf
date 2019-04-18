#!/usr/bin/env bash
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker_version=$(cat "$curDir"/VERSION)

echo "building version: ${docker_version} locally"

docker build --build-arg PCF_CLI_VERSION="${docker_version}" --pull -t docker-cicd-pcf:"${docker_version}" -t docker-cicd-pcf:latest .
# docker push mrllsvc/pcf-tools:"${docker_version}"
# docker push mrllsvc/pcf-tools:latest