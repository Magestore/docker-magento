#!/usr/bin/env sh

set +x

if [[ ! -z "${JENKINS_DATA}" ]]; then
    cd $JENKINS_DATA/workspace/$JOB_BASE_NAME
fi

# Finish script here
HASH_NAME=`echo -n "$HTTP_SERVER-$PHP_VERSION-$MAGENTO_VERSION-$GITHUB_REPO-$GITHUB_BRANCH-$BUILD_NUMBER" | sha1sum | cut -d' ' -f 1`

if [ -d "$HASH_NAME" ]; then
    cd $HASH_NAME
    # Stop service
    docker-compose down
    cd .. && rm -rf $HASH_NAME
fi

docker volume prune -f
