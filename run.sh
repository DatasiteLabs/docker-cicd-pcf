#!/usr/bin/env bash
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker_version=$(cat VERSION)

usage() {
    cat <<END
${curDir}/run.sh [cf] deploy-params.json
cf: optionally execute cf commands against your space
defaults to rolling deploy script

Run the docker container for mrllsvc/pcf-tools:${docker_version}
    -h: show this help message
END
}

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
			-t --rm \
			--name pcf-tools \
			-v "${curDir}"/tools/:/home/pcf/tools \
			mrllsvc/pcf-tools:"${docker_version}" bash rolling-deploy.sh -d "$@"
else
	echo "running cf cli"
	shift
	docker run \
			-t --rm \
			--name pcf-tools \
			-v "${curDir}"/tools/:/home/pcf/tools \
			mrllsvc/pcf-tools:"${docker_version}" bash cf-cli.sh -d "$@"
fi