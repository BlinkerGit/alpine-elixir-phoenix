#!/bin/bash

set -ex

echo "docker buildx setup..."

docker info
docker run --privileged --rm tonistiigi/binfmt --install all
docker context create tls-env
docker buildx use $(docker buildx create tls-env)

export IMAGE_NAME=blinker/alpine-elixir-phoenix
export ELIXIR_VERSION=$(cat Dockerfile | grep FROM | sed -e 's/.*://' | sed -e 's/-.*//')
export ELIXIR_MINOR=$(echo $ELIXIR_VERSION | sed 's/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\(\.[0-9][0-9]*\)*/\1.\2/')

export ERLANG_VERSION=$(cat Dockerfile | grep FROM | sed -e 's/.*erlang-//' | sed -e 's/-.*//')
export ALPINE_VERSION=$(cat Dockerfile | grep FROM | sed -e 's/.*alpine-//' | sed -e 's/-.*//')
export DOCKER_TAG=$ELIXIR_VERSION-erlang-$ERLANG_VERSION-alpine-$ALPINE_VERSION

if [[ "$CIRCLE_BRANCH" == "main" ]]; then
  echo "======================================================================"
  echo "On main branch. Building and pushing new image to container registry..."

  docker buildx build --push --platform linux/amd64,linux/arm64 --force-rm \
        --progress=plain \
        -t $IMAGE_NAME:$DOCKER_TAG \
        -t $IMAGE_NAME:$ELIXIR_VERSION \
        -t $IMAGE_NAME:$ELIXIR_MINOR \
        -t $IMAGE_NAME:latest \
        - < ./Dockerfile

  echo "----------------------------------------------------------------------"
  echo "build and push complete"
else
  echo "======================================================================"
  echo "Not on main branch; testing build only..."

  docker buildx build --platform linux/amd64,linux/arm64 --force-rm \
        --progress=plain \
        -t $IMAGE_NAME:$DOCKER_TAG \
        -t $IMAGE_NAME:$ELIXIR_VERSION \
        -t $IMAGE_NAME:$ELIXIR_MINOR \
        -t $IMAGE_NAME:latest \
        - < ./Dockerfile

  echo "----------------------------------------------------------------------"
  echo "test build complete"
fi
