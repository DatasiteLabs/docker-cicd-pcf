#!/usr/bin/env bash
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker_version=$(cat "$curDir"/VERSION)

usage() {
    cat <<END
${curDir}/build.sh [-v]

Build docker container and push to dockerhub mrllsvc/
    -v: bump the version
    -h: show this help message
END
}

while getopts ":hv" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        v)
            version_num=$((docker_version+1))
            echo "${version_num}" > VERSION
            docker_version="${version_num}"
            ;;
        :)
            error "Option -${OPTARG} is missing an argument" 2
            ;;
        \?)
            error "unkown option: -${OPTARG}" 3
            ;;
    esac
done

echo "building and pushing version: ${docker_version}"

docker build --pull -t mrllsvc/pcf-tools:"${docker_version}" -t mrllsvc/pcf-tools:latest .
docker push mrllsvc/pcf-tools:"${docker_version}"
docker push mrllsvc/pcf-tools:latest