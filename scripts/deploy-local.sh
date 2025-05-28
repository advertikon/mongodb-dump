echo "Building image..."

docker build -t mongodb-dump:latest  .

RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo " ⛔  Build failed. Exit"
    exit $RESULT
fi

EXISTS=$(docker container ls -a -q -f 'name=mongodb-dump')
IS_RUNNING=$(docker ps -q --filter "name=mongodb-dump")

if [ -n "$IS_RUNNING" ]; then
    echo "Stopping running container..."
    docker stop "$IS_RUNNING"
    echo "Removing stopped container..."
    docker rm "$IS_RUNNING"
elif [ -n "$EXISTS" ]; then
    echo "Removing existing container..."
    docker rm "$EXISTS"
fi

echo "Running Docker image..."

set -a
source .env
set +a

docker run --name mongodb-dump \
    --add-host=host.docker.internal:host-gateway --network=host \
    --env MONGODB_HOST="$MONGODB_HOST" \
    --env MONGODB_USER="$MONGODB_USERNAME" \
    --env MONGODB_PASSWORD="$MONGODB_PASSWORD" \
    --env S3_BUCKET="$AWS_S3_BUCKET_NAME" \
    --env AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    --env AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    --env AWS_REGION="$AWS_REGION" \
	mongodb-dump:latest