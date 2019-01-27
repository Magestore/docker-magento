#!/usr/bin/env sh
echo "This step running on node $NODE_NAME"

if [[ ! -z "${JENKINS_DATA}" ]]; then
    cd $JENKINS_DATA/workspace/$JOB_BASE_NAME
fi

# Build script here
set -x
COMPOSE_FILE="magento-$MAGENTO_VERSION/$HTTP_SERVER/docker-compose.php-$PHP_VERSION.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "We do not support for Magento $MAGENTO_VERSION on $HTTP_SERVER with php $PHP_VERSION"
    exit 1
fi

HASH_NAME=`echo -n "$HTTP_SERVER-$PHP_VERSION-$MAGENTO_VERSION-$GITHUB_REPO-$GITHUB_BRANCH" | sha1sum | cut -d' ' -f 1`

if [ -d "$HASH_NAME" ]; then
    echo 'Server is running...'
    exit
fi

mkdir $HASH_NAME && cd $HASH_NAME

# Build WebPOS and deploy to Magento Server
GITHUB_URL="https://$GITHUB_USERNAME:$GITHUB_PASSWORD@github.com/$GITHUB_REPO"
IS_PULL=`node -e "if ('$GITHUB_BRANCH'.indexOf('/') !== -1) console.log('1');"`

git init && git remote add origin $GITHUB_URL
if [[ -z "${IS_PULL}" ]]; then
    echo "Checking out branch $GITHUB_BRANCH..."
    git fetch --depth 1 origin $GITHUB_BRANCH
else
    echo "Checking out pull request $GITHUB_BRANCH..."
    git fetch --depth 1 origin +refs/$GITHUB_BRANCH/merge
fi
git checkout FETCH_HEAD
rm -rf .git
if [ $? -ne 0 ]; then
    exit 1
fi

# Build POS
cd client/pos
#npm install && npm run build
cd ../..
#mkdir -p server/app/code/Magestore/Webpos/build/apps
#rm -Rf server/app/code/Magestore/Webpos/build/apps/pos
#cp -Rf client/pos/build server/app/code/Magestore/Webpos/build/apps/pos

# Start service
cp ../$COMPOSE_FILE docker-compose.yml
COMPOSE_HTTP_TIMEOUT=200 docker-compose up -d

# check db container is run correctly
WHILE_LIMIT=10 # timeout 360 seconds
while ! DBISUP=`docker-compose ps | grep 3306 | grep Up`
do
    if [ ! -z "$DBISUP" ]; then
        break
    else
        docker-compose rm db # remove stopped container
        COMPOSE_HTTP_TIMEOUT=200 docker-compose up -d
        if [ $WHILE_LIMIT -lt 1 ]; then
            break
        fi
    fi
    WHILE_LIMIT=$(( WHILE_LIMIT - 1 ))
    sleep 3
done

echo "Wait for mysql work"
COMPOSE_HTTP_TIMEOUT=200 docker-compose exec -T magento php mysql.php

# Install magento
echo "Install magento"
set +x
MAGENTO_CMD='php bin/magento setup:install --use-rewrites=1 \
--db-host=db \
--db-name=magento \
--db-password=magento \
--db-prefix=m_ \
--admin-firstname=Admin \
--admin-lastname=MFTF \
--admin-email=admin@localhost.com \
--admin-user=admin \
--admin-password=admin123 \
--base-url=$BASE_URL \
--backend-frontname=admin \
--admin-use-security-key=0 \
--key=8f1e9249ca82c072122ae8d08bc0b0cf '
set -x
docker-compose exec -u www-data -T magento bash -c "$MAGENTO_CMD"

# Check magento installation
# COUNT_LIMIT=240 # timeout 600 seconds
# while ! RESPONSE=`docker-compose exec -T magento curl -s https://localhost.com/magento_version`
# do
#     if [ $COUNT_LIMIT -lt 1 ]; then
#         break
#     fi
#     COUNT_LIMIT=$(( COUNT_LIMIT - 1 ))
#     sleep 5
# done

# echo "Wait for magento setup start"
# #var/.maintenance.flag
# TIME_OUT=10 # seconds
# while [ -z "`docker-compose exec -T magento ps auxww | grep 'bin/magento setup'`" ]
# do
#     if [ $TIME_OUT -lt 1 ]; then
#         echo "Something error:=========="
#         docker-compose ps
#         echo "See logs:================="
#         docker-compose logs
#         exit 1
#         #reak
#     fi
#     TIME_OUT=$(( TIME_OUT - 1 ))
#     sleep 1
# done

# echo "Wait for magento setup stop"
# COUNT_LIMIT=1000 # timeout 3000 seconds
# while [ ! -z "`docker-compose exec -T magento ps auxww | grep 'bin/magento setup'`" ]
# do
#     if [ $COUNT_LIMIT -lt 1 ]; then
#         break
#     fi
#     COUNT_LIMIT=$(( COUNT_LIMIT - 1 ))
#     sleep 3
# done

#check maintenance flag
! `docker-compose exec -T magento [ -f var/.maintenance.flag ]` || sh -c "\
    echo 'Magento is maintenance mode try to restart container'; \
    COMPOSE_HTTP_TIMEOUT=200 docker-compose restart magento "

# Wait for magento setup start
# TIME_OUT=10 # seconds
# while [ -z "`docker-compose exec -T magento ps auxww | grep 'bin/magento setup'`" ]
# do
#     if [ $TIME_OUT -lt 1 ]; then
#         break
#     fi
#     TIME_OUT=$(( TIME_OUT - 1 ))
#     sleep 1
# done

# Wait for magento setup stop
# COUNT_LIMIT=1000 # seconds
# while [ ! -z "`docker-compose exec -T magento ps auxww | grep 'bin/magento setup'`" ]
# do
#     if [ $COUNT_LIMIT -lt 1 ]; then
#         break
#     fi
#     COUNT_LIMIT=$(( COUNT_LIMIT - 1 ))
#     sleep 3
# done

sleep 3
echo "Check magento installation"
COUNT_LIMIT=10 # timeout 600 seconds
while ! RESPONSE=`docker-compose exec -T magento curl -s localhost/magento_version`
do
    if [ $COUNT_LIMIT -lt 1 ]; then
        break
    fi
    COUNT_LIMIT=$(( COUNT_LIMIT - 1 ))
    sleep 3
done

if [[ "${RESPONSE:0:8}" != "Magento/" ]]; then
    echo "Cannot setup magento"
    sleep 1000
    exit 1
fi

# recheck and wait for db is up
# if [[ ${RESPONSE:0:8} != "Magento/" ]]; then
#     COMPOSE_HTTP_TIMEOUT=200 docker-compose restart magento
#     PORT=`docker-compose port --protocol=tcp magento 80 | sed 's/0.0.0.0://'`
#     MAGENTO_URL="http://$NODE_IP:$PORT"
#     RETRY_LIMIT=1 # retry 1 loop
#     COUNT_OUT_LIMIT=100 # timeout 300 seconds
#     while ! docker-compose exec -T magento curl -s https://localhost.com/magento_version
#     do
#         COUNT_OUT_LIMIT=$(( COUNT_OUT_LIMIT - 1 ))
#         if [ $COUNT_OUT_LIMIT -lt 1 ]; then
#             # if database cannot start or error try to restart it
#             if [ -z "$(docker-compose ps | grep 3306 | grep Up)" ]; then
#                 docker-compose rm db # remove stopped container
#                 COMPOSE_HTTP_TIMEOUT=200 docker-compose up -d
#                 COUNT_OUT_LIMIT=100
#                 RETRY_LIMIT=$(( RETRY_LIMIT - 1 ))
#             else
#                 break
#             fi
#             if [ $RETRY_LIMIT -lt 1 ]; then
#                 echo "Error with db logs:"
#                 docker-compose logs db
#                 exit 1
#             fi
#         fi
#         sleep 3
#     done
# fi

PORT=`docker-compose port --protocol=tcp magento 80 | sed 's/0.0.0.0://'`
MAGENTO_URL="http://$NODE_IP:$PORT"

# Correct magento url
docker-compose exec -u www-data -T magento bash -c \
    "php bin/magento setup:store-config:set \
    --admin-use-security-key=0 \
    --base-url=$MAGENTO_URL/ "

# Upgrade module (if needed)
# install POS
echo "Install POS modules:"
sed -i 's/#AUTO_ADD_VOLUME_server_app_code_Magestore/- \.\/server\/app\/code\/Magestore:\/var\/www\/html\/app\/code\/Magestore/g' docker-compose.yml
docker-compose up -d

# Wait for server
sleep 5

docker-compose exec -u www-data -T magento bash -c "php bin/magento setup:upgrade"
docker-compose exec -u www-data -T magento bash -c "php bin/magento webpos:deploy"

# Update config for testing
MAGENTO_CMD='php bin/magento config:set cms/wysiwyg/enabled disabled \
&& php bin/magento config:set admin/security/admin_account_sharing 1 \
&& php bin/magento config:set admin/captcha/enable 0 '
docker-compose exec -u www-data -T magento bash -c "$MAGENTO_CMD"

