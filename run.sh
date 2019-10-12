#!/bin/sh

# Import GPG public keys
gpg --import /keys/*

if [ ${RUN_NOW:-0} -ne 0 ]; then
  /backup.sh
fi
# Create and install crontab file
echo "$CRON_INTERVAL /backup.sh" >> /backup.cron

crontab /backup.cron

crond -f -d 8
