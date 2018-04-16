#!/usr/bin/env bash
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker_version=$(cat VERSION)

usage() {
    cat <<END
${curDir}/run.sh

Run the docker container for mrllsvc/pcf-tools:${docker_version}
    -h: show this help message
END
}

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

docker run \
		-d -t --rm \
		--name pcf-tools \
		-u pcf \
		mrllsvc/pcf-tools:"${docker_version}"