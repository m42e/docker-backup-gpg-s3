#!/bin/sh

BACKUP_DATE=$(date +"%Y-%m-%d")
BACKUP_BASENAME=$S3_BUCKET_NAME$BACKUP_DATE.tar
SKIP_XZ=${ONLY_TAR:-0}

month_day=`date +"%d"`

if [ $SKIP_XZ -ne 0 ]; then
  TAR_PARAM=
  BACKUP_FILENAME=daily_$BACKUP_BASENAME
  BACKUP_FILENAME_MONTHLY=monthly_$BACKUP_BASENAME
else
  TAR_PARAM=-J
  BACKUP_FILENAME=daily_$BACKUP_BASENAME.xz
  BACKUP_FILENAME_MONTHLY=monthly_$BACKUP_BASENAME.xz
fi

cd /backup
echo "make archive"
tar -c --checkpoint=.1000 ${TAR_PARAM} -f ~/$BACKUP_FILENAME ./*
cd /
echo " done"

RECIPIENT=$(echo "$GPG_RECIPIENT" | sed "s/,/ --recipient /")

echo "encrypting"
gpg --trust-model always --enable-progress-filter --output ~/$BACKUP_FILENAME.gpg --encrypt --recipient $RECIPIENT ~/$BACKUP_FILENAME
rm ~/$BACKUP_FILENAME

echo "uploading"
aws s3 cp ~/$BACKUP_FILENAME.gpg s3://$S3_BUCKET_NAME/$BACKUP_FILENAME.gpg --storage-class STANDARD_IA
rm ~/$BACKUP_FILENAME.gpg
echo "done"

# On first month day do
if [ "$month_day" -eq 1 ] ; then
  echo "make monthly backup"
  aws s3 s3://$S3_BUCKET_NAME/$BACKUP_FILENAME.gpg s3://$S3_BUCKET_NAME/$BACKUP_FILENAME_MONTHLY.gpg --storage-class DEEP_ARCHIVE
fi
