#!/bin/bash

ENVIRONMENT=$RAILS_ENV
ODSA_BRANCH=$ODSA_BRANCH
LTI_BRANCH=$LTI_BRANCH

OPENDSA_DIR="/opendsa"
APP_DIR="/opendsa-lti"
APP_LOG_FILE="/opendsa-lti/log/development.log"
PORT="80"

ERROR_FOUND=false;

echo "-------------------------------------------------------"
echo "Checkout LTI branch"
git checkout ${LTI_BRANCH}
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "Create the log file"
touch /opendsa-lti/log/development.log
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "Create database.yml"
cp /opendsa-lti/config/databasedemo.yml /opendsa-lti/config/database.yml
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "updating permissions" #>> ${OPENDSA_LOG_FILE} 2>&1
ln -s /opendsa /opendsa-lti/public/OpenDSA || ERROR_FOUND=true
if [[ "${ERROR_FOUND}" == true ]]; then cp -r /opendsa /opendsa-lti/public/OpenDSA && ERROR_FOUND=false; fi;
echo "-------------------------------------------------------"

cd "${OPENDSA_DIR}"
echo "-------------------------------------------------------"
echo "git checkout ${ODSA_BRANCH}"
git checkout ${ODSA_BRANCH}
echo "make -f Makefile pull" #>> ${OPENDSA_LOG_FILE} 2>&1
make -f Makefile pull #>> ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

#echo "-------------------------------------------------------"
#echo "make -f Makefile venv" #>> ${OPENDSA_LOG_FILE} 2>&1
#make -f Makefile venv #>> ${OPENDSA_LOG_FILE} 2>&1
#sudo mkdir -p /home/deploy/OpenDSA
#sudo cp -r .pyVenv/ /home/deploy/OpenDSA/
#. .pyVenv/bin/activate
#echo "cd /home/deploy/OpenDSA" >> /root/.bashrc
#echo ". .pyVenv/bin/activate" >> /root/.bashrc
#echo "cd /opendsa-lti" >> /root/.bashrc
#echo "-------------------------------------------------------"

#echo "-------------------------------------------------------"
#echo "pip install -r requirements.txt --ignore-installed" #>> ${OPENDSA_LOG_FILE} 2>&1
#pip install -r requirements.txt --ignore-installed #>> ${OPENDSA_LOG_FILE} 2>&1
#echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "make allbooks" #>> ${OPENDSA_LOG_FILE} 2>&1
bash -c "source /opendsa/.pyVenv/bin/activate && make allbooks" #>> ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "Copying configuration files"
cp /opendsa-lti/config/databasedemo.yml /opendsa-lti/config/database.yml || ERROR_FOUND=true

#if [[ "${ERROR_FOUND}" == true ]]; then exit 1; fi;

echo "-------------------------------------------------------"
cd "${APP_DIR}"
echo "nohup bash -c rake jobs:work" >> ${APP_LOG_FILE} 2>&1
nohup bash -c "rake jobs:work >> ${APP_LOG_FILE} 2>&1 &"
echo "-------------------------------------------------------"

#echo "Setting up database"
#echo "-------------------------------------------------------"
#echo "RAILS_ENV=$RAILS_ENV bundle exec db:schema:load" #>> ${APP_LOG_FILE} 2>&1
#RAILS_ENV=${ENVIRONMENT} bundle exec rake db:schema:load #>> ${APP_LOG_FILE} 2>&1
#echo "RAILS_ENV=$RAILS_ENV bundle exec db:seed" #>> ${APP_LOG_FILE} 2>&1
#RAILS_ENV=${ENVIRONMENT} bundle exec rake db:seed #>> ${APP_LOG_FILE} 2>&1
echo "RAILS_ENV=$RAILS_ENV bundle exec db:populate" #>> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec rake db:populate #>> ${APP_LOG_FILE} 2>&1
#echo "-------------------------------------------------------"

echo "Starting server"
echo "-------------------------------------------------------"
#echo "RAILS_ENV=$RAILS_ENV bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt -p ${PORT}" #>> ${APP_LOG_FILE} 2>&1
echo "RAILS_ENV=$RAILS_ENV bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt -p ${PORT}"
#RAILS_ENV=${ENVIRONMENT} bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt -p ${PORT} #>> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec thin start -p ${PORT} #>> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"
