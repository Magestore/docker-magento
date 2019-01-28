#!/usr/bin/env sh
echo "This step running on node $NODE_NAME"

if [[ ! -z "${JENKINS_DATA}" ]]; then
    cd $JENKINS_DATA/workspace/$JOB_BASE_NAME
fi

HASH_NAME=`echo -n "$HTTP_SERVER-$PHP_VERSION-$MAGENTO_VERSION-$GITHUB_REPO-$GITHUB_BRANCH" | sha1sum | cut -d' ' -f 1`
cd $HASH_NAME

PORT=`docker-compose port --protocol=tcp magento 80 | sed 's/0.0.0.0://'`
if [[ -z "$PORT" ]]; then
    echo "Server is not running..."
    exit 1
fi

MAGENTO_URL="http://$NODE_IP:$PORT"
MAGENTO_SECURE_URL="http://$NODE_IP:$PORT"

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
echo "         $MAGENTO_SECURE_URL/admin"
echo "POS:     $MAGENTO_URL/pub/apps/pos/"
echo "         $MAGENTO_SECURE_URL/pub/apps/pos/"
echo "Admin: admin/admin123"
echo "PHPMyAdmin: $PHPMYADMIN_URL"
echo "MAIL BOX: $EMAIL_URL"
echo ""

# Slack hook
INFO="\n"
INFO="${INFO}Server Info: $HTTP_SERVER php-$PHP_VERSION Magento-$MAGENTO_VERSION \n"
INFO="${INFO}Built from: $GITHUB_REPO $GITHUB_BRANCH \n"
INFO="${INFO}\n"
INFO="${INFO}Magento: $MAGENTO_URL/admin \n"
INFO="${INFO}         $MAGENTO_SECURE_URL/admin \n"
INFO="${INFO}POS:     $MAGENTO_URL/pub/apps/pos/ \n"
INFO="${INFO}         $MAGENTO_SECURE_URL/pub/apps/pos/ \n"
INFO="${INFO}Admin: admin/admin123 \n"
INFO="${INFO}PHPMyAdmin: $PHPMYADMIN_URL \n"
INFO="${INFO}MAIL BOX: $EMAIL_URL \n"
INFO="${INFO}"

curl -X POST -s --data-urlencode "payload={\"text\": \"[RUNNING] <$RUN_DISPLAY_URL|$BUILD_DISPLAY_NAME> $INFO \"}" $SLACK_HOOKS_POS4

# Living time
set -x
sleep $TIME_TO_LIVE
