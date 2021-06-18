# docker-cicd-pcf

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/datasite/docker-cicd-pcf?style=for-the-badge)

alpine based docker container with pcf tools installed. also has: bash, jq, curl, git, tar, gzip...
Includes a rolling-deploy.sh script to do a rolling deploy in your foundry.

## updating

1. change the VERSION file text to your target version to avoid clobbering existing versions. [see versions](#versions)

## Opening a PR

* Use a meaningful title, it will be used as the release title
* Use a meaningful commit message, it will be used as the release message

## versions

Manually versioned and latest stored in VERSION file. See https://github.com/cloudfoundry/cli/releases for CLI releases. Version should likely match your target PCF env version, find that from /tools in your PCF env.

**Use the cli version as the number for clarity and the build hooks use this to download the correct version.**

> If you need to amend the version in between, use '-blah' or '-fix-blah', the hyphen will break the cli version from arbitrary information.

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

## releasing a new version

Script assumes the following:

* You have latest code pulled down
* HEAD on master branch is the code to be released

```bash
./release.sh
```

## code style / guidelines

set your IDE to use shellcheck: https://www.shellcheck.net/

use the google shell styleguide: https://google.github.io/styleguide/shell.xml