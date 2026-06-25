#!/bin/sh
set -eu

mkdir -p /data/data /data/home /data/logs /data/workspaces
if [ ! -e /app/data ]; then
  ln -s /data/data /app/data
fi
if [ ! -e /app/logs ]; then
  ln -s /data/logs /app/logs
fi
chown -R node:node /data

exec gosu node "$@"
