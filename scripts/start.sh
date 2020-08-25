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
make -f Makefile pull >>  ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "pip install -r requirements.txt --ignore-installed" >> ${OPENDSA_LOG_FILE} 2>&1
pip install -r requirements.txt --ignore-installed >> ${OPENDSA_LOG_FILE} 2>&1

echo "-------------------------------------------------------"
echo "make allbooks" >> ${OPENDSA_LOG_FILE} 2>&1
make allbooks >> ${OPENDSA_LOG_FILE} 2>&1
echo "-------------------------------------------------------"


echo "Copying configuration files from NFS conf directory"
cp "${EFS_DIR}/databasedemo.yml" "${APP_DIR}/config/database.yml" || ERROR_FOUND=true

if [[ "${ERROR_FOUND}" == true ]]; then exit 1; fi;


echo "-------------------------------------------------------"
cd "${APP_DIR}"
echo "nohup bash -c rake jobs:work" >> ${APP_LOG_FILE} 2>&1  
nohup bash -c "rake jobs:work >> ${APP_LOG_FILE} 2>&1 &"
echo "-------------------------------------------------------"

echo "-------------------------------------------------------"
echo "RAILS_ENV=$RAILS_ENV bundle exec thin start -p ${PORT}" >> ${APP_LOG_FILE} 2>&1
RAILS_ENV=${ENVIRONMENT} bundle exec thin start -p ${PORT} >> ${APP_LOG_FILE} 2>&1
echo "-------------------------------------------------------"

#lsof -t -i tcp:${PORT} | xargs kill -9
#echo "RAILS_ENV=$RAILS_ENV rails s  -b 0.0.0.0 -p ${PORT}"
#RAILS_ENV=${ENVIRONMENT} rails s  -b 0.0.0.0 -p ${PORT} >> $APP_LOG_FILE 2>&1


