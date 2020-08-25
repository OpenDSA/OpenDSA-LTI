#!/bin/bash

export PATH=$PATH:/home/ubuntu/.rvm/rubies/ruby-2.7.1/bin/

#LOCALHOST
APP_DIR="/apps/opendsa-lti/"
#EFS_DIR="/var/tmp/credentials"
RAILS_ENV='development'
PORT="3000"

# Change file permissions

find ${APP_DIR} -type d -exec chmod 2775 {} \;
find ${APP_DIR} -type f -exec chmod 0644 {} \;

#Map gemset file
cd "${APP_DIR}"
rvm gemset use opendsa-6.0.3

ENVIRONMENT=$RAILS_ENV
ERROR_FOUND=false;


# Install Required gems
cd "${APP_DIR}"
bundle install

which bundle >> /apps/opendsa-lti/log/development.log 2>&1
bundle version >> /apps/opendsa-lti/log/development.log 2>&1

# Create Soft link
ln -s /apps/opendsa /apps/opendsa-lti/public/OpenDSA

# Copy required files
cp /apps/config/database.yml /apps/opendsa-lti/config/database.yml
cp /apps/config/development.rb /apps/opendsa-lti/config/environments/development.rb
cp /apps/opendsa-lti/postprocessor.py /apps/opendsa-lti/public/OpenDSA/tools/postprocessor.py


if [[ "${ERROR_FOUND}" == true ]]; then exit 1; fi;

cd "${APP_DIR}"

echo "Start rake:work in the background - Executes delayed_jobs:"
# Kill running process
ps aux |grep "rake jobs:work" |grep -v grep| awk '{print $2 }'|xargs -I{} kill {}
nohup bundle exec rake jobs:work >> /apps/opendsa-lti/log/development.log 2>&1 &

echo "RAILS_ENV=$RAILS_ENV bundle exec thin start -p ${PORT}"
# Kill running process
lsof -t -i tcp:${PORT} | xargs kill -9
RAILS_ENV=${ENVIRONMENT} bundle exec thin start -p ${PORT} -d  >> /apps/opendsa-lti/log/development.log 2>&1