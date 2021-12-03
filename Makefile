.PHONY: help

VERSION ?= `cat Dockerfile | grep FROM | sed -e 's/.*://' | sed -e 's/-.*//'`
MAJ_VERSION := $(shell echo $(VERSION) | sed 's/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\(\.[0-9][0-9]*\)*/\1/')
MIN_VERSION := $(shell echo $(VERSION) | sed 's/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\(\.[0-9][0-9]*\)*/\1.\2/')
IMAGE_NAME ?= blinker/alpine-elixir-phoenix

ALPINE_VERSION ?= `cat Dockerfile | grep FROM | sed -e 's/.*alpine-//' | sed -e 's/-.*//'`
ERLANG_VERSION ?= `cat Dockerfile | grep FROM | sed -e 's/.*erlang-//' | sed -e 's/-.*//'`
ERLANG_MAJOR := $(shell echo $(ERLANG_VERSION) | sed -e 's/\..*//')

help:
	@echo "$(IMAGE_NAME):$(VERSION)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

elixir:
	@echo "building elixir ${VERSION} base image..."
	docker build --force-rm --build-arg OS_VERSION=$(ALPINE_VERSION) --build-arg ERLANG=$(ERLANG_VERSION) --build-arg ERLANG_MAJOR=$(ERLANG_MAJOR) --build-arg ELIXIR=$(VERSION) -t blinker/elixir:$(VERSION)-erlang-$(ERLANG_VERSION)-alpine-$(ALPINE_VERSION) -f Dockerfile.elixir .

erlang:
	@echo "building erlang ${ERLANG_VERSION} base image..."
	docker build --force-rm --build-arg OS_VERSION=$(ALPINE_VERSION) --build-arg ERLANG=$(ERLANG_VERSION) -t blinker/erlang:$(ERLANG_VERSION)-alpine-$(ALPINE_VERSION) -f Dockerfile.erlang .

test: ## Test the Docker image
	docker run --rm -it $(IMAGE_NAME):$(VERSION) elixir --version

shell: ## Run an Elixir shell in the image
	docker run --rm -it $(IMAGE_NAME):$(VERSION) iex

sh: ## Boot to a shell prompt
	docker run --rm -it $(IMAGE_NAME):$(VERSION) /bin/bash

build: ## Build the Docker image
	docker build --force-rm -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):$(MIN_VERSION) -t $(IMAGE_NAME):$(MAJ_VERSION) -t $(IMAGE_NAME):latest - < ./Dockerfile

clean: ## Clean up generated images
	@docker rmi --force $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(MIN_VERSION) $(IMAGE_NAME):$(MAJ_VERSION) $(IMAGE_NAME):latest

rebuild: clean build ## Rebuild the Docker image

release: build ## Rebuild and release the Docker image to Docker Hub
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest
