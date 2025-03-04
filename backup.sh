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

healthchck_fail(){
	if [ -n $HEALTHCHECK_URL ]; then
	 	curl --retry 3 $HEALTHCHECK_URL/fail
		exit 1
	fi
}

healthchck_ok(){
	if [ -n $HEALTHCHECK_URL ]; then
	 	curl --retry 3 $HEALTHCHECK_URL
	fi
}

cd /backup
echo "make archive"
tar -c --checkpoint=.1000 ${TAR_PARAM} ${TAR_EXTRA_PARAM} -f ~/$BACKUP_FILENAME ./* || healthchck_fail
cd /
echo " done"

RECIPIENT=$(echo "$GPG_RECIPIENT" | sed "s/,/ --recipient /")

echo "encrypting"
gpg --trust-model always --enable-progress-filter --output ~/$BACKUP_FILENAME.gpg --encrypt --recipient $RECIPIENT ~/$BACKUP_FILENAME || healthchck_fail
rm ~/$BACKUP_FILENAME

echo "uploading"
aws s3 cp ~/$BACKUP_FILENAME.gpg s3://$S3_BUCKET_NAME/$BACKUP_FILENAME.gpg --storage-class STANDARD_IA || healthchck_fail
rm ~/$BACKUP_FILENAME.gpg
echo "done"

# On first month day do
if [ "$month_day" -eq 1 ] ; then
  echo "make monthly backup"
  aws s3 cp s3://$S3_BUCKET_NAME/$BACKUP_FILENAME.gpg s3://$S3_BUCKET_NAME/$BACKUP_FILENAME_MONTHLY.gpg --storage-class DEEP_ARCHIVE || (curl --retry 3 https://health.d1v3.de/ping/8183024f-0aa5-4e19-90a2-c1325a5408ae/fail && exit 1)
fi
healthchck_ok
