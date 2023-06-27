#!/bin/bash

set -ex

echo "docker buildx setup..."

docker info
docker run --privileged --rm tonistiigi/binfmt --install all
docker context create tls-env
docker buildx use $(docker buildx create tls-env)

export IMAGE_NAME=blinker/alpine-elixir-phoenix
export VERSION=$(cat Dockerfile | grep FROM | sed -e 's/.*://' | sed -e 's/-.*//')
export MIN_VERSION=$(echo $VERSION | sed 's/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\(\.[0-9][0-9]*\)*/\1.\2/')

if [[ "$CIRCLE_BRANCH" == "main" ]]; then
  echo "======================================================================"
  echo "On main branch. Building and pushing new image to container registry..."

  docker buildx build --push --platform linux/amd64,linux/arm64 --force-rm \
        --progress=plain \
        -t $IMAGE_NAME:$CIRCLE_SHA1 \
        -t $IMAGE_NAME:$VERSION \
        -t $IMAGE_NAME:$MIN_VERSION \
        -t $IMAGE_NAME:latest \
        - < ./Dockerfile

  echo "----------------------------------------------------------------------"
  echo "build and push complete"
else
  echo "======================================================================"
  echo "Not on main branch; testing build only..."

  docker buildx build --platform linux/amd64,linux/arm64 --force-rm \
        --progress=plain \
        -t $IMAGE_NAME:$CIRCLE_SHA1 \
        -t $IMAGE_NAME:$VERSION \
        -t $IMAGE_NAME:$MIN_VERSION \
        -t $IMAGE_NAME:latest \
        - < ./Dockerfile

  echo "----------------------------------------------------------------------"
  echo "test build complete"
fi
