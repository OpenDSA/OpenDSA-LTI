#!/bin/bash
set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

exec bundle exec "$@"
