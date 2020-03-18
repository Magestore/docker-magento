#!/usr/bin/env sh

echo "Running on node $NODE_NAME"

if [[ ! -z "${JENKINS_DATA}" ]]; then
    cd $JENKINS_DATA/workspace/$JOB_BASE_NAME
fi

HASH_NAME=`echo -n "$HTTP_SERVER-$PHP_VERSION-$MAGENTO_VERSION-$GITHUB_REPO-$GITHUB_BRANCH-$BUILD_NUMBER" | sha1sum | cut -d' ' -f 1`
cd $HASH_NAME

PORT=`docker-compose port --protocol=tcp magento 80 | sed 's/0.0.0.0://'`
if [[ -z "$PORT" ]]; then
    echo "Server is not running..."
    exit 1
fi

MAGENTO_URL="http://$NODE_IP:$PORT"

PORT=`docker-compose port --protocol=tcp phpmyadmin 80 | sed 's/0.0.0.0://'`
PHPMYADMIN_URL="http://$NODE_IP:$PORT"

PORT=`docker-compose port --protocol=tcp mailhog 8025 | sed 's/0.0.0.0://'`
EMAIL_URL="http://$NODE_IP:$PORT"

# Show Information
echo ""
echo "Server Info: $HTTP_SERVER php-$PHP_VERSION Magento-$MAGENTO_VERSION"
echo "Built from: $GITHUB_REPO $GITHUB_BRANCH"
echo ""
echo "Magento: $MAGENTO_URL/admin"
echo "Admin: admin/admin123"
echo "PHPMyAdmin: $PHPMYADMIN_URL"
echo "EMAIL: $EMAIL_URL"
echo ""

# Living time
set -x
sleep $TIME_TO_LIVE
