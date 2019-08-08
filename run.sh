#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
[[ ${DEBUG:-} == true ]] && set -o xtrace
readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker_version=$(cat VERSION)

usage() {
    cat <<END
${__dir}/run.sh [cf] -t [targetDir]
cf: optionally execute cf commands against your space
[-t targetDir]: required for rolling deploy test, dir to deploy app from
deploy-params.json: json with values consumed by rolling-deploy.sh, see toos/deploy-params.json.example for format
defaults to rolling deploy script

Run the docker container for docker-cicd-pcf:${docker_version}
    -h: show this help message
END
}

error() {
    echo "Error: $1"
    exit "$2"
} >&2

# TODO: swithc default mode to cf.

while getopts ":ht:" opt; do
    case $opt in
    h)
        usage
        exit 0
        ;;
    t)
        target_dir="${__dir}/${OPTARG}"
        ;;
    :)
        error "Option -${OPTARG} is missing an argument" 2
        ;;
    \?)
        error "unkown option: -${OPTARG}" 3
        ;;
    esac
done

declare cf_cli=false
declare json_file="tools/deploy-params.json"

shift $((OPTIND - 1))
[[ ${1:-} == 'cf' ]] && cf_cli=true
[[ -f "${json_file}" ]] || {
    echo "${json_file} doesn't exist. copy example file and edit." >&2
    exit 1
}

if [[ ${cf_cli} == false ]]; then
    [[ ! -d "${target_dir:-}" ]] && error "-t targetDir: ${target_dir:-} doesn't exist." 1
    echo "running rolling deploy"
    docker run \
        -ti --rm \
        --name docker-cicd-pcf \
        -e DEBUG="${DEBUG:-}" \
        -v "${__dir}"/tools/:/home/pcf/tools \
        -v "${target_dir}"/:/home/pcf/dist \
        docker-cicd-pcf:"${docker_version}" bash rolling-deploy.sh "${json_file}" "$@"
else
    echo "running cf cli"
    shift
    docker run \
        -ti --rm \
        --name docker-cicd-pcf \
        -v "${__dir}"/tools/:/home/pcf/tools \
        docker-cicd-pcf:"${docker_version}" bash cf-cli.sh "${json_file}" "$@"
fi
