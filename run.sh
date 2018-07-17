#!/usr/bin/env bash
set -o errexit
set -o nounset

curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker_version=$(cat VERSION)

usage() {
    cat <<END
${curDir}/run.sh [cf] deploy-params.json
cf: optionally execute cf commands against your space
deploy-params.json: json with values consumed by rolling-deploy.sh, see toos/deploy-params.json.example for format
defaults to rolling deploy script

Run the docker container for mrllsvc/pcf-tools:${docker_version}
    -h: show this help message
END
}

error () {
    echo "Error: $1"
    exit "$2"
} >&2

# TODO: swithc default mode to cf.

while getopts ":h" opt; do
    case $opt in
        h)
            usage
            exit 0
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
shift $(( OPTIND -1 ))
[[ $1 == 'cf' ]] && cf_cli=true

if [[ ${cf_cli} == false ]]; then
	echo "running rolling deploy"
	docker run \
			-ti --rm \
			--name pcf-tools \
			-v "${curDir}"/tools/:/home/pcf/tools \
			mrllsvc/pcf-tools:"${docker_version}" bash rolling-deploy.sh -d "$@"
else
	echo "running cf cli"
	shift
	docker run \
			-ti --rm \
			--name pcf-tools \
			-v "${curDir}"/tools/:/home/pcf/tools \
			mrllsvc/pcf-tools:"${docker_version}" bash cf-cli.sh -d "$@"
fi