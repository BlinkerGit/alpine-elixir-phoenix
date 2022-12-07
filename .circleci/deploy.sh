#!/bin/bash
# This script is meant to be run from a Circle CI job to automatically build a new version of the Docker container and
# push it to the container registry

set -ex

echo "docker buildx setup..."
docker info
docker run --privileged --rm tonistiigi/binfmt --install all
docker context create tls-env
docker buildx use $(docker buildx create tls-env)

if [[ "$CIRCLE_BRANCH" == "main" ]]; then
  echo "======================================================================"
  echo "On main branch. Building and pushing new image to container registry..."

  make release

  echo "----------------------------------------------------------------------"
  echo "build and push complete"
else
  echo "======================================================================"
  echo "Not on main branch; testing build only..."

  make build

  echo "----------------------------------------------------------------------"
  echo "test build complete"
fi
