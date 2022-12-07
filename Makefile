.PHONY: help

VERSION := $(shell cat Dockerfile | grep FROM | sed -e 's/.*://' | sed -e 's/-.*//')
MAJ_VERSION := $(shell echo $(VERSION) | sed 's/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\(\.[0-9][0-9]*\)*/\1/')
MIN_VERSION := $(shell echo $(VERSION) | sed 's/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\(\.[0-9][0-9]*\)*/\1.\2/')
IMAGE_NAME ?= blinker/alpine-elixir-phoenix

ALPINE_VERSION := $(shell cat Dockerfile | grep FROM | sed -e 's/.*alpine-//' | sed -e 's/-.*//')
ERLANG_VERSION := $(shell cat Dockerfile | grep FROM | sed -e 's/.*erlang-//' | sed -e 's/-.*//')
ERLANG_MAJOR := $(shell echo $(ERLANG_VERSION) | sed -e 's/\..*//')

DOCKER_TAG := $(VERSION)-erlang-$(ERLANG_VERSION)-alpine-$(ALPINE_VERSION)

help:
	@echo "$(IMAGE_NAME):$(VERSION)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

latest_elixir:
	@curl -s https://repo.hex.pm/builds/elixir/builds.txt \
	   | grep '^v\d\+\.\d\+\.\d\+' \
		 | awk '{print $$1}' \
		 | awk '{ if ($$1 ~ /-/) print; else print $$0"_" ; }' \
		 | sort -rV \
		 | sed 's/_$$//' \
		 | grep otp \
		 | head -1

latest_erlang:
	@curl -s https://api.github.com/repos/erlang/otp/releases \
	   | jq -r '.[].tag_name' \
		 | sort -rV \
		 | head -1

test: ## Test the Docker image
	docker run --rm -it $(IMAGE_NAME):$(VERSION) elixir --version

shell: ## Run an Elixir shell in the image
	docker run --rm -it $(IMAGE_NAME):$(VERSION) iex

sh: ## Boot to a shell prompt
	docker run --rm -it $(IMAGE_NAME):$(VERSION) /bin/bash

erlang: ## build the erlang base image
	@echo "building erlang ${ERLANG_VERSION} base image..."
	docker buildx build --platform linux/amd64,linux/arm64 --force-rm \
				 --build-arg OS_VERSION=$(ALPINE_VERSION) \
				 --build-arg ERLANG=$(ERLANG_VERSION) \
				 -t blinker/erlang:$(ERLANG_VERSION)-alpine-$(ALPINE_VERSION) \
				 - < ./Dockerfile.erlang

elixir: erlang ## build the elixir base image
	@echo "building elixir ${VERSION} base image..."
	docker buildx build --platform linux/amd64,linux/arm64 --force-rm \
				 --build-arg OS_VERSION=$(ALPINE_VERSION) \
				 --build-arg ERLANG=$(ERLANG_VERSION) \
				 --build-arg ERLANG_MAJOR=$(ERLANG_MAJOR) \
				 --build-arg ELIXIR=$(VERSION) \
				 -t blinker/elixir:$(VERSION)-erlang-$(ERLANG_VERSION)-alpine-$(ALPINE_VERSION) \
				 - < ./Dockerfile.elixir

build: elixir ## Build the Docker image
	docker buildx build --platform linux/amd64,linux/arm64 --force-rm \
				 -t $(IMAGE_NAME):$(DOCKER_TAG) \
				 -t $(IMAGE_NAME):$(VERSION) \
				 -t $(IMAGE_NAME):$(MIN_VERSION) \
				 -t $(IMAGE_NAME):latest \
				 - < ./Dockerfile
	@echo "$(IMAGE_NAME):$(DOCKER_TAG)"

clean: ## Clean up generated images
	@docker rmi --force $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(MIN_VERSION) $(IMAGE_NAME):latest

rebuild: clean build ## Rebuild the Docker image

release: elixir## Build and release the Docker image to Docker Hub
	docker buildx build --push --platform linux/amd64,linux/arm64 --force-rm \
				 -t $(IMAGE_NAME):$(DOCKER_TAG) \
				 -t $(IMAGE_NAME):$(VERSION) \
				 -t $(IMAGE_NAME):$(MIN_VERSION) \
				 -t $(IMAGE_NAME):latest \
				 - < ./Dockerfile
