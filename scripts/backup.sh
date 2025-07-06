#!/bin/env bash

if [ -z "$MONGODB_HOST" ]; then
    echo " ⛔  MONGODB_HOST variable is not set. Exit"
    exit 1
fi

if [ -z "$MONGODB_USER" ]; then
    echo " ⛔  MONGODB_USER variable is not set. Exit"
    exit 1
fi

if [ -z "$MONGODB_PASSWORD" ]; then
    echo " ⛔  MONGODB_PASSWORD variable is not set. Exit"
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo " ⛔  AWS_ACCESS_KEY_ID variable is not set. Exit"
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo " ⛔  AWS_SECRET_ACCESS_KEY variable is not set. Exit"
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    echo " ⛔  AWS_REGION variable is not set. Exit"
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo " ⛔  S3_BUCKET variable is not set. Exit"
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
    exit $RESULT
fi

echo " ✔ Backup completed successfully."
echo " ✔ Backup files:"
ls -lh ./backup

echo " ✔ Uploading backup to S3..."
aws s3 cp ./backup "s3://$S3_BUCKET/" --recursive

RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo " ⛔  Upload to S3 failed. Exit"
    exit $RESULT
else
    echo " ✔ Backup uploaded to S3 successfully."
fi
