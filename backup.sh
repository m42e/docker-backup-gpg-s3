#!/bin/sh

BACKUP_DATE=$(date +"%Y-%m-%d_%H-%M")

cd /backup
echo "make archive"
tar -c --checkpoint=.1000 -Jf ~/$S3_BUCKET_NAME$BACKUP_DATE.tar.xz ./*
cd /

RECIPIENT=$(echo "$GPG_RECIPIENT" | sed "s/,/ --recipient /")

echo "encrypting"
gpg --trust-model always --enable-progress-filter --output ~/$S3_BUCKET_NAME$BACKUP_DATE.tar.xz.gpg --encrypt --recipient $RECIPIENT ~/$S3_BUCKET_NAME$BACKUP_DATE.tar.xz
rm ~/$S3_BUCKET_NAME$BACKUP_DATE.tar.xz

echo "uploading"
aws s3 cp ~/$S3_BUCKET_NAME$BACKUP_DATE.tar.xz.gpg s3://$S3_BUCKET_NAME/$S3_BUCKET_NAME$BACKUP_DATE.tar.xz.gpg --storage-class STANDARD_IA
rm ~/$S3_BUCKET_NAME$BACKUP_DATE.tar.xz.gpg
echo "done"
