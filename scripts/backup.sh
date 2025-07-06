#!/bin/env bash

set -e

DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"/..

function notifySlack() {
    if [ -n "$SLACK_MESSAGES_WEBHOOK" ]; then
        wget -qO- "$SLACK_MESSAGES_WEBHOOK" --post-data "{\"text\":\"$1\"}" --header 'Content-Type: application/json'
    fi
}

notifySlack "[MongoDB dump]: 🤖 MongoDB Backup script started."

if [ -z "$MONGODB_HOST" ]; then
    echo " ⛔  MONGODB_HOST variable is not set. Exit"
    notifySlack "[MongoDB dump]: ⛔ MONGODB_HOST variable is not set. Exit"
    exit 1
fi

if [ -z "$MONGODB_USER" ]; then
    echo " ⛔  MONGODB_USER variable is not set. Exit"
    notifySlack "[MongoDB dump]: ⛔ MONGODB_USER variable is not set. Exit"
    exit 1
fi

if [ -z "$MONGODB_PASSWORD" ]; then
    echo " ⛔  MONGODB_PASSWORD variable is not set. Exit"
    notifySlack "[MongoDB dump]: ⛔ MONGODB_PASSWORD variable is not set. Exit"
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo " ⛔  AWS_ACCESS_KEY_ID variable is not set. Exit"
    notifySlack "[MongoDB dump]: ⛔ AWS_ACCESS_KEY_ID variable is not set. Exit"
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo " ⛔  AWS_SECRET_ACCESS_KEY variable is not set. Exit"
    notifySlack "[MongoDB dump]: ⛔ AWS_SECRET_ACCESS_KEY variable is not set. Exit"
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    echo " ⛔  AWS_REGION variable is not set. Exit"
    notifySlack "[MongoDB dump]: ⛔ AWS_REGION variable is not set. Exit"
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo " ⛔  S3_BUCKET variable is not set. Exit"
    notifySlack "[MongoDB dump]: ⛔ S3_BUCKET variable is not set. Exit"
    exit 1
fi

if [ -d "./backup" ]; then
    rm -rf ./backup
    echo " ✔ Old backup directory removed."
fi

mkdir -p ./backup
mongodump --uri="mongodb://$MONGODB_HOST" -u "$MONGODB_USER" -p "$MONGODB_PASSWORD" --gzip --archive="./backup/mongo-local-backup-$(date +%Y-%m-%d_%H-%M-%S).gz"

RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo " ⛔  Backup failed. Exit"
    notifySlack "[MongoDB dump]: ⛔ Backup failed. Exit"
    exit $RESULT
fi

echo " ✔ Backup completed successfully."
echo " ✔ Backup files:"
ls -lh ./backup

FILES_COUNT=$(ls ./backup | wc -l)
echo " ✔ Number of backup files: $FILES_COUNT"

if [ $FILES_COUNT -eq 0 ]; then
    echo " ⛔  No backup files created. Exit"
    notifySlack "[MongoDB dump]: ⛔ No backup files created. Exit"
    exit 1
fi

echo " ✔ Uploading backup to S3..."
aws s3 cp ./backup "s3://$S3_BUCKET/" --recursive

RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo " ⛔  Upload to S3 failed. Exit"
    notifySlack "[MongoDB dump]: ⛔ Upload to S3 failed. Exit"
    exit $RESULT
fi
    
echo " ✔ Backup uploaded to S3 successfully"
notifySlack "[MongoDB dump]: 🍾 MongoDB Backup script completed successfully"
