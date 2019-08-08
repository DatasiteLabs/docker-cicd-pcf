#!/usr/bin/env bash
readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pcf_cli_version=$(sed s/[-a-zA-Z]*$// <"${__dir}"/VERSION)
docker_version=$(cat "${__dir}"/VERSION)

echo "building version: ${docker_version} locally"

docker build --build-arg PCF_CLI_VERSION="${pcf_cli_version}" --pull -t docker-cicd-pcf:"${docker_version}" -t docker-cicd-pcf:latest "${__dir}"
# docker push mrllsvc/pcf-tools:"${docker_version}"
# docker push mrllsvc/pcf-tools:latest
