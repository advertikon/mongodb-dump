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

echo " ✔ Downloading backup from S3..."
echo "Available backups:"
aws s3 ls s3://mv-mongo-dump | awk '{print $4}'

BACKUP=$(aws s3 ls s3://mv-mongo-dump | awk '{a[i++]=$4} END{print a[i-1]}')

if [ -z "$BACKUP" ]; then
    echo " ⛔  No backups found in S3. Exit"
    exit 1
fi

if [ -d "./backup" ]; then
    rm -rf ./backup
    echo " ✔ Old backup directory removed."
fi

mkdir -p ./backup

echo "Downloading backup: $BACKUP"
aws s3 cp "s3://$S3_BUCKET/$BACKUP" ./backup/

RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo " ⛔  Download from S3 failed. Exit"
    exit $RESULT
else
    echo " ✔ Backup downloaded from S3 successfully."
fi

echo " ✔ Extracting backup..."
mongorestore --uri="mongodb://$MONGODB_HOST" -u "$MONGODB_USER" -p "$MONGODB_PASSWORD" --gzip --archive="./backup/$BACKUP"

RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo " ⛔  Restore failed. Exit"
    exit $RESULT
fi

echo " ✔ Restore completed successfully."
