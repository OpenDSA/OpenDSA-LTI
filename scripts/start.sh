#!/bin/bash

ENVIRONMENT=$RAILS_ENV
ODSA_BRANCH=$ODSA_BRANCH
LTI_BRANCH=$LTI_BRANCH

OPENDSA_DIR="/opendsa"
APP_DIR="/opendsa-lti"
APP_LOG_FILE="/opendsa-lti/log/development.log"
PORT="8443"

ERROR_FOUND=false;

checkout_branch_if_needed() {
  local branch="$1"
  local current_branch

  current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [ "${current_branch}" = "${branch}" ]; then
    echo "Already on ${branch}; skipping checkout"
  else
    git checkout "${branch}"
  fi
}

echo "-------------------------------------------------------"
echo "Checkout LTI branch"
checkout_branch_if_needed "${LTI_BRANCH}"
echo "-------------------------------------------------------"
echo "Create the log file"
touch /opendsa-lti/log/development.log
echo "-------------------------------------------------------"
echo "Create database.yml"
cp /opendsa-lti/config/database.yml.example /opendsa-lti/config/database.yml
echo "-------------------------------------------------------"
echo "Create application.yml"
cp /opendsa-lti/config/application.yml.example /opendsa-lti/config/application.yml
echo "-------------------------------------------------------"
echo "updating permissions" #>> ${OPENDSA_LOG_FILE} 2>&1
if [ ! -L /opendsa-lti/public/OpenDSA ] || [ "$(readlink /opendsa-lti/public/OpenDSA)" != "/opendsa" ]; then
  rm -rf /opendsa-lti/public/OpenDSA
  ln -s /opendsa /opendsa-lti/public/OpenDSA
fi
cd "${OPENDSA_DIR}"
echo "-------------------------------------------------------"
echo "git checkout ${ODSA_BRANCH}"
checkout_branch_if_needed "${ODSA_BRANCH}"
echo "-------------------------------------------------------"
cd "${APP_DIR}"
echo "nohup bash -c rake jobs:work" >> ${APP_LOG_FILE} 2>&1
nohup bash -c "rake jobs:work >> ${APP_LOG_FILE} 2>&1 &"
echo "-------------------------------------------------------"
echo "Starting cron and installing whenever schedule"
echo "-------------------------------------------------------"
(
  service cron start >/dev/null 2>&1 || cron
  bundle exec whenever --update-crontab opendsa-lti --set "environment=${ENVIRONMENT}" --load-file config/schedule.rb
) &
echo "-------------------------------------------------------"
echo "Starting server"
echo "-------------------------------------------------------"
echo "RAILS_ENV=${ENVIRONMENT} bundle exec puma -C config/puma-dev.rb"
RAILS_ENV=${ENVIRONMENT} bundle exec puma -C config/puma-dev.rb
echo "-------------------------------------------------------"
