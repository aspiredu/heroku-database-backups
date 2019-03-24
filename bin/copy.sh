#!/bin/bash

# terminate script as soon as any command fails
set -e

if [[ -z "$APP" ]]; then
  echo "Missing APP variable which must be set to the name of your app where the db is located"
  exit 1
fi

if [[ -z "$S3_BUCKET_PATH" ]]; then
  echo "Missing S3_BUCKET_PATH variable which must be set the directory in s3 where you would like to store your database backups"
  exit 1
fi

# Find the latest backup if none given
if [[ -z "$1" ]]; then
  BAK_ID="$(heroku pg:backups --app $APP | grep Completed | head -n 1 | awk -F '  ' '{print $1}')"
else
  BAK_ID="$1"
fi

# Get the date of the given, or latest, backup
BAK_DATE=$(heroku pg:backups:info $BAK_ID --app $APP | grep "Started at" | head -n 1 | awk -F ': ' '{print $2}')

#install aws-cli
curl https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o awscli-bundle.zip
unzip awscli-bundle.zip
chmod +x ./awscli-bundle/install
./awscli-bundle/install -i /tmp/aws

BACKUP_FILE_NAME="$(date -d "$BAK_DATE" +"%Y-%m-%d-%H-%M")-$APP.dump"

curl -o $BACKUP_FILE_NAME `heroku pg:backups:url $BAK_ID --app $APP`
FINAL_FILE_NAME=$BACKUP_FILE_NAME

# if [[ -z "$NOGZIP" ]]; then
#   gzip $BACKUP_FILE_NAME
#   FINAL_FILE_NAME=$BACKUP_FILE_NAME.gz
# fi

/tmp/aws/bin/aws s3 cp $FINAL_FILE_NAME s3://$S3_BUCKET_PATH/$APP/$FINAL_FILE_NAME

echo "backup $FINAL_FILE_NAME complete"

