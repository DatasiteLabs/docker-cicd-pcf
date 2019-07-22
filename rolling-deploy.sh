#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
[[ ${DEBUG:-} == true ]] && set -o xtrace

usage() {
    cat <<END
rolling-deploy.sh [-d] jsonFile

Rolling deploy for pcf with reasonable scaling
jsonFile: jsonFile with all the vars needed to run the script. see: example
    -h: show this help message
END
}

error() {
    echo "Error: $1"
    exit "$2"
} >&2

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

shift $((OPTIND - 1))
[[ -f ${1} ]] || {
    echo "missing an argument. first argument must be location of json file with vars" >&2
    exit 1
}
declare json_file="${1}"

# set cf vars
# read -r CF_API_ENDPOINT CF_BUILDPACK CF_USER CF_PASSWORD CF_ORG CF_SPACE CF_INTERNAL_APPS_DOMAIN CF_EXTERNAL_APPS_DOMAIN <<<"$(jq '.cf | @sh "\(.api_endpoint) \(.buildpack) \(.user) \(.password) \(.org) \(.space) \(.apps_domain.internal) \(.apps_domain.external)"' "${json_file}" | tr -d \" )"
# eval "$(jq -r '.cf | @sh "CF_API_ENDPOINT=\(.api_endpoint) CF_BUILDPACK=\(.buildpack) CF_USER=\(.user) CF_PASSWORD=\(.password) CF_ORG=\(.org) CF_SPACE=\(.space) CF_INTERNAL_APPS_DOMAIN=\(.apps_domain.internal) CF_EXTERNAL_APPS_DOMAIN=\(.apps_domain.external)"' "${json_file}" "
eval "$(
    jq -r '.cf | @sh "
CF_API_ENDPOINT=\(.api_endpoint) 
CF_BUILDPACK=\(.buildpack) 
CF_USER=\(.user) 
CF_PASSWORD=\(.password) 
CF_ORG=\(.org) 
CF_SPACE=\(.space) 
CF_INTERNAL_APPS_DOMAIN=\(.apps_domain.internal) 
CF_EXTERNAL_APPS_DOMAIN=\(.apps_domain.external)
"' "${json_file}"
)"
# read -r APP_NAME SCALE_MEMORY SCALE_DISK_LIMIT SCALE_INSTANCES ARTIFACT_PATH BUILD_NUMBER EXTERNAL_APP_HOSTNAME PUSH_OPTIONS <<<"$(jq '@sh "\(.app_name) \(.scale.memory_limit) \(.scale.disk_limit) \(.scale.instances) \(.artifact_path) \(.build_number) \(.external_app_hostname) \(.push_options)"' "${json_file}" | tr -d \")"
eval "$(
    jq -r '@sh "
APP_NAME=\(.app_name)
SCALE_MEMORY=\(.scale.memory_limit)
SCALE_DISK_LIMIT=\(.scale.disk_limit)
SCALE_INSTANCES=\(.scale.instances)
ARTIFACT_PATH=\(.artifact_path)
BUILD_NUMBER=\(.build_number)
EXTERNAL_APP_HOSTNAME=\(.external_app_hostname)
PUSH_OPTIONS=\(.push_options)
"' "${json_file}"
)"
readarray -t CF_SERVICES <<<"$(jq -r '.cf.services[]' "${json_file}")"

if [[ ${DEBUG:-} == true ]]; then
    set +o xtrace
    echo "CF_API_ENDPOINT: ${CF_API_ENDPOINT}"
    echo "CF_BUILDPACK: ${CF_BUILDPACK}"
    echo "CF_USER: ${CF_USER}"
    echo "CF_PASSWORD: ${CF_PASSWORD}"
    echo "CF_ORG: ${CF_ORG}"
    echo "CF_SPACE: ${CF_SPACE}"
    echo "CF_SERVICES[@]: ${CF_SERVICES[*]}"
    echo "CF_INTERNAL_APPS_DOMAIN: ${CF_INTERNAL_APPS_DOMAIN}"
    echo "CF_EXTERNAL_APPS_DOMAIN: ${CF_EXTERNAL_APPS_DOMAIN}"
    echo "APP_NAME: ${APP_NAME}"
    echo "SCALE_MEMORY: ${SCALE_MEMORY}"
    echo "SCALE_DISK_LIMIT: ${SCALE_DISK_LIMIT}"
    echo "SCALE_INSTANCES: ${SCALE_INSTANCES}"
    echo "ARTIFACT_PATH: ${ARTIFACT_PATH}"
    echo "BUILD_NUMBER: ${BUILD_NUMBER}"
    echo "EXTERNAL_APP_HOSTNAME: ${EXTERNAL_APP_HOSTNAME}"
    echo "PUSH_OPTIONS: ${PUSH_OPTIONS}"
    set -o xtrace
fi

cf api --skip-ssl-validation "${CF_API_ENDPOINT}"
cf login -u "${CF_USER}" -p "${CF_PASSWORD}" -o "${CF_ORG}" -s "${CF_SPACE}"

DEPLOYED_APP="${APP_NAME}"
space_guid=$(cf space "${CF_SPACE}" --guid)
declare TARGET_INSTANCES
declare DEPLOYED_APP_INSTANCES
DEPLOYED_APP_INSTANCES=$(cf curl /v2/apps -X GET -H 'Content-Type: application/x-www-form-urlencoded' -d "q=name:${DEPLOYED_APP}" | jq -r --arg DEPLOYED_APP "${DEPLOYED_APP}" \
    ".resources[] | select(.entity.space_guid == \"${space_guid}\") | select(.entity.name == \"${DEPLOYED_APP}\") | .entity.instances | numbers")

# DEPLOYED_APP_INSTANCES is currently deployed and may not match defined if autoscaled or manually scaled
# SCALE_INSTANCES is read from the json file and is expected target.
# match DEPLOYED if exists, else match defined. This should prevent stragglers with a mismatch.
# doesn't handle supporting downsizing on deploy
if [[ -z "${DEPLOYED_APP_INSTANCES}" ]]; then
    echo "No instances currently deployed."
    TARGET_INSTANCES="${SCALE_INSTANCES}"
else
    TARGET_INSTANCES="${DEPLOYED_APP_INSTANCES}"
fi

[[ ${DEBUG:-} == true ]] && echo "DEPLOYED APP: ${DEPLOYED_APP} DEPLOYED APP INSTANCES: ${TARGET_INSTANCES}"

[[ -d ${ARTIFACT_PATH} ]] || (echo "exiting before deploy. ${ARTIFACT_PATH} does not exist" && exit 1)

declare NEW_APP_NAME="${APP_NAME}-${BUILD_NUMBER}"

cf push "${NEW_APP_NAME}" -i 1 -m "${SCALE_MEMORY}" -k "${SCALE_DISK_LIMIT}" \
    -n "${NEW_APP_NAME}" -d "${CF_INTERNAL_APPS_DOMAIN}" \
    -b "${CF_BUILDPACK}" \
    -p "${ARTIFACT_PATH}" ${PUSH_OPTIONS}

cf set-env "${APP_NAME}" JFROG_ARTIFACTORY_VERSION "${BUILD_NUMBER}"

for CF_SERVICE in "${CF_SERVICES[@]}"; do
    if [ -n "${CF_SERVICE}" ]; then
        echo "Binding service ${CF_SERVICE}"
        cf bind-service "${NEW_APP_NAME}" "${CF_SERVICE}"
    fi
done

cf start "${NEW_APP_NAME}"

echo "Performing zero-downtime cutover to ${NEW_APP_NAME}"
cf map-route "${NEW_APP_NAME}" "${CF_EXTERNAL_APPS_DOMAIN}" -n "${EXTERNAL_APP_HOSTNAME}"

echo "A/B deployment"
if [[ -n "${DEPLOYED_APP}" && -n "${TARGET_INSTANCES}" ]]; then

    declare -i instances=0
    declare -i old_app_instances=${TARGET_INSTANCES}
    echo "begin scaling down from: ${TARGET_INSTANCES}"

    while ((${instances} != ${TARGET_INSTANCES})); do
        declare -i instances=${instances}+1
        declare -i old_app_instances=${old_app_instances}-1
        echo "Scaling up ${NEW_APP_NAME} to ${instances}.."
        cf scale -i ${instances} "${NEW_APP_NAME}"

        if [[ ${DEPLOYED_APP_INSTANCES} -gt 0 ]]; then
            echo "Scaling down ${DEPLOYED_APP} to ${old_app_instances}.."
            cf scale -i ${old_app_instances} "${DEPLOYED_APP}"

            echo "Unmapping the external route from the application ${DEPLOYED_APP}"
            cf unmap-route "${DEPLOYED_APP}" "${CF_EXTERNAL_APPS_DOMAIN}" -n "${EXTERNAL_APP_HOSTNAME}"

            echo "Deleting the application ${DEPLOYED_APP}"
            cf delete "${DEPLOYED_APP}" -f
        else
            echo "deployed instances was: ${DEPLOYED_APP_INSTANCES}, skipping scaling down, unmapping route and deleting old app."
        fi
    done
fi

# TODO: move rename into replace delete old app to keep metrics
#echo "Renaming ${APP_NAME} to ${APP_NAME}-old"
#cf rename "${APP_NAME}" "${APP_NAME}-old"
#
echo "Renaming ${NEW_APP_NAME} to ${APP_NAME}"
cf rename "${NEW_APP_NAME}" "${APP_NAME}"

echo "Deleting the orphaned routes"
cf delete-orphaned-routes -f || echo 'deleting orphaned routes failed.'
