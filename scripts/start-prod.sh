#!/bin/bash

ENVIRONMENT=$RAILS_ENV
ODSA_BRANCH=$ODSA_BRANCH
LTI_BRANCH=$LTI_BRANCH

OPENDSA_DIR="/opendsa"
APP_DIR="/opendsa-lti"
APP_LOG_FILE="/opendsa-lti/log/development.log"
PORT="8443"

ERROR_FOUND=false;

echo "-------------------------------------------------------"
echo "Checkout LTI branch"
git checkout ${LTI_BRANCH}
echo "-------------------------------------------------------"
echo "Create the log file"
touch /opendsa-lti/log/development.log
echo "-------------------------------------------------------"
echo "updating permissions" #>> ${OPENDSA_LOG_FILE} 2>&1
rm -rf /opendsa/lti/public/OpenDSA
ln -s /opendsa /opendsa-lti/public/OpenDSA
cd "${OPENDSA_DIR}"
echo "-------------------------------------------------------"
echo "git checkout ${ODSA_BRANCH}"
git checkout ${ODSA_BRANCH}
echo "-------------------------------------------------------"
cd "${APP_DIR}"
echo "nohup bash -c rake jobs:work" >> ${APP_LOG_FILE} 2>&1
nohup bash -c "rake jobs:work >> ${APP_LOG_FILE} 2>&1 &"
echo "-------------------------------------------------------"
echo "Starting server"
echo "-------------------------------------------------------"
echo "RAILS_ENV=${ENVIRONMENT} bundle exec puma -C config/puma-prod.rb"
RAILS_ENV=${ENVIRONMENT} bundle exec puma -C config/puma-prod.rb
echo "-------------------------------------------------------"
