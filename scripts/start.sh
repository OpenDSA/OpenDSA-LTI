#!/bin/bash

ENVIRONMENT=$RAILS_ENV

OPENDSA_DIR="/opendsa"
APP_DIR="/opendsa-lti"
OPENDSA_LOG_FILE="/opendsa/opendsa.log"
APP_LOG_FILE="/opendsa-lti/log/development.log"
EFS_DIR="/var/tmp/credentials"
PORT="80"

#LOCALHOST
#EFS_DIR="${APP_DIR}"
#PORT="3000"

ERROR_FOUND=false;

echo "-------------------------------------------------------"
echo "Create the log file"
touch /opendsa-lti/log/development.log
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "Create database.yml"
cp /opendsa-lti/config/databasedemo.yml /opendsa-lti/config/database.yml
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "updating permissions" >> ${OPENDSA_LOG_FILE} 2>&1
# find /opendsa-lti -type d -exec chmod 2775 {} \;
# find /opendsa-lti -type f -exec chmod 0644 {} \;
# find ./scripts -type f -exec chmod +x {} \;
ln -s /opendsa /opendsa-lti/public/OpenDSA
echo "-------------------------------------------------------"

cd "${OPENDSA_DIR}"
echo "-------------------------------------------------------"
echo "checkout python3" >> ${OPENDSA_LOG_FILE} 2>&1
git checkout python3 >> ${OPENDSA_LOG_FILE} 2>&1
git pull >> ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "ln -s ${EFS_DIR}/opendsademo/Books ${OPENDSA_DIR}" >> ${OPENDSA_LOG_FILE} 2>&1
ln -s ${EFS_DIR}/opendsademo/Books ${OPENDSA_DIR} >> ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "make -f Makefile pull" >> ${OPENDSA_LOG_FILE} 2>&1
make -f Makefile pull >> ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "make -f Makefile venv" >> ${OPENDSA_LOG_FILE} 2>&1
make -f Makefile venv >> ${OPENDSA_LOG_FILE} 2>&1
sudo mkdir -p /home/deploy/OpenDSA
sudo cp -r .pyVenv/ /home/deploy/OpenDSA/
. .pyVenv/bin/activate
echo "cd /home/deploy/OpenDSA" >> /home/vagrant/.bashrc
echo ". .pyVenv/bin/activate" >> /home/vagrant/.bashrc
echo "cd /opendsa-lti" >> /home/vagrant/.bashrc
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "pip install -r requirements.txt --ignore-installed" >> ${OPENDSA_LOG_FILE} 2>&1
pip install -r requirements.txt --ignore-installed >> ${OPENDSA_LOG_FILE} 2>&1

echo "-------------------------------------------------------"
echo "make allbooks" >> ${OPENDSA_LOG_FILE} 2>&1
make allbooks >> ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "make venv"
make venv
echo "-------------------------------------------------------"

echo "Copying configuration files"
# cp "${EFS_DIR}/databasedemo.yml" "${APP_DIR}/config/database.yml" || ERROR_FOUND=true
cp /opendsa-lti/config/databasedemo.yml /opendsa-lti/config/database.yml || ERROR_FOUND=true

if [[ "${ERROR_FOUND}" == true ]]; then exit 1; fi;


echo "-------------------------------------------------------"
cd "${APP_DIR}"
echo "nohup bash -c rake jobs:work" >> ${APP_LOG_FILE} 2>&1
nohup bash -c "rake jobs:work >> ${APP_LOG_FILE} 2>&1 &"
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "RAILS_ENV=$RAILS_ENV bundle exec db:drop" # >> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec rake db:drop # >> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "RAILS_ENV=$RAILS_ENV bundle exec db:create" # >> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec rake db:create # >> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "RAILS_ENV=$RAILS_ENV bundle exec db:schema:load" >> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec rake db:schema:load >> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "RAILS_ENV=$RAILS_ENV bundle exec db:seed" # >> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec rake db:seed # >> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "RAILS_ENV=$RAILS_ENV bundle exec db:populate" # >> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec rake db:populate # >> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "RAILS_ENV=$RAILS_ENV bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt -p ${PORT}" # >> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec thin start --ssl --ssl-key-file server.key --ssl-cert-file server.crt -p ${PORT} # >> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

# lsof -t -i tcp:${PORT} | xargs kill -9
# echo "RAILS_ENV=$RAILS_ENV rails s  -b 0.0.0.0 -p ${PORT}"
# RAILS_ENV=${ENVIRONMENT} rails s  -b 0.0.0.0 -p ${PORT} >> $APP_LOG_FILE 2>&1
