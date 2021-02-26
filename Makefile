.DEFAULT_GOAL := help

PWD ?= $$(pwd)
USERID ?= $$(id -u)

PYTHON_VERSION=3.6.5
EDX_PLATFORM_VERSION=open-release/juniper.master

DOCKER_RUN=docker run --rm -it \
	-v $(PWD)/edx-platform/locale/:/openedx/edx-platform/conf/locale/ \
	-v ${HOME}/.transifexrc:/openedx/.transifexrc \
	-v $(PWD)/edx-platform/.tx/:/openedx/edx-platform/.tx/:ro \
	openedx-i18n

all: build download validate compile ## Download and compile translations from transifex

transifexrc: ## Make sure an empty transifexrc credentials file exists
	touch transifexrc

shell: transifexrc ## Open a bash shell in the openedx container
	$(DOCKER_RUN) bash

build: ## Build the docker image that contains translations
	docker build -t openedx-i18n \
		--build-arg USERID=$(USERID) \
		--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
		--build-arg EDX_PLATFORM_VERSION=$(EDX_PLATFORM_VERSION) \
		./docker

download: transifexrc ## Download i18n files from transifex
	$(DOCKER_RUN) i18n_tool transifex --config=conf/locale/config-extra.yaml rtl
	$(DOCKER_RUN) i18n_tool transifex --config=conf/locale/config-extra.yaml ltr

validate: ## Check for errors in translation files
	$(DOCKER_RUN) i18n_tool validate --config=conf/locale/config-extra.yaml

compile: ## Compile i18n files
	$(DOCKER_RUN) bash -c "\
		cd conf/locale && i18n_tool generate -v --config=./config-extra.yaml"

clean: ## Clean useless i18n files
	git clean -Xfd -- edx-platform/

help: ## generate this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
