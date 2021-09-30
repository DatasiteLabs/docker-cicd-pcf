#!/usr/bin/env bash
readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker_version=$(cat "${__dir}"/VERSION)
pcf_cli_version="${docker_version%%-*}"

echo "building version: ${docker_version} locally"

docker build --build-arg PCF_CLI_VERSION="${pcf_cli_version}" --pull -t datasite/docker-cicd-pcf:"${docker_version}" -t datasite/docker-cicd-pcf:latest "${__dir}"
# docker push mrllsvc/pcf-tools:"${docker_version}"
# docker push mrllsvc/pcf-tools:latest
