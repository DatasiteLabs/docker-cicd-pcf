# docker-cicd-pcf

[![Docker Build Status](https://img.shields.io/docker/build/merrillcorporation/docker-cicd-pcf.svg?style=for-the-badge)](https://hub.docker.com/r/merrillcorporation/docker-cicd-pcf/builds/)

alpine based docker container with pcf tools installed. also has: bash, jq, curl, git, tar, gzip...
Includes a rolling-deploy.sh script to do a rolling deploy in your foundry.

## updating

1. change the VERSION file text to your target version to avoid clobbering existing versions. [see versions](#versions)

## versions

Manually versioned and latest stored in VERSION file. See https://github.com/cloudfoundry/cli/releases for CLI releases. Version should likely match your target PCF env version, find that from /tools in your PCF env.

**Use the cli version as the number for clarity.**

## getting started

This requires a lot of env vars to work. see example in: tools/deploy-params.json.example

`cp tools/deploy-params.json.example tools/deploy-params.json`

edit your values in the new file.

*NOTE*: these are sensitive values, ignored by github and .dockerignore. if building in CI make sure you cleanup after creating the file.

## run

### ./run.sh wrapper script

#### rolling deploy

`./run.sh tools/deploy-params.json`

#### cf commands

example of cf target, any cf command will pass through

`./run.sh cf target`

### docker run example

```bash
docker run \
            -ti --rm \
            --name pcf-tools \
            mrllsvc/pcf-tools:10 bash
```
