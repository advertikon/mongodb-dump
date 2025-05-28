#!/bin/bash

DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"/..
set -e

if [ -z "$1" ]; then
  echo " ⛔  Next version number missing. Exit"
  exit 1
fi

if [ -z "$IMAGE" ]; then
  echo " ⛔  IMAGE variable is not set. Exit"
  exit 1
fi

PACKAGE_VERSION=$1
TAGGED="${IMAGE}:${PACKAGE_VERSION}"

echo " ✔ Package version: ${PACKAGE_VERSION}"

echo " ✔ Building image ${TAGGED}";
docker build -t "${TAGGED}" .

echo " ✔ Pushing image"
docker push "$TAGGED"

echo " ✔ Pushing latest image"
docker tag "$TAGGED" "${IMAGE}:latest"
docker push "${IMAGE}:latest"

echo " ✔ Updating image in Kubernetes"
kubectl --insecure-skip-tls-verify set image -n prod deployment/mongodb-dump mongodb-dump="${IMAGE}:${PACKAGE_VERSION}"
kubectl --insecure-skip-tls-verify rollout status deployment/mongodb-dump -n prod
