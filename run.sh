#!/bin/sh

# Import GPG public keys
gpg --import /keys/*

# Create and install crontab file
echo "$CRON_INTERVAL /backup.sh" >> /backup.cron

crontab /backup.cron

crond -f -d 8
