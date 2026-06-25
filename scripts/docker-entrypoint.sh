#!/bin/sh
set -eu

mkdir -p /data/data /data/home /data/logs /data/workspaces
if [ ! -e /app/data ]; then
  ln -s /data/data /app/data
fi
if [ ! -e /app/logs ]; then
  ln -s /data/logs /app/logs
fi
chown node:node /data /data/home
chown -R node:node /data/data /data/logs /data/workspaces

exec gosu node "$@"
