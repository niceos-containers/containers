.PHONY: test-compat test-compat-network test-compat-reference

IMAGE ?= docker.io/niceos/golang
APP_VERSION ?= 1.26.4
NICEOS_STREAM ?= 13
IMAGE_REVISION ?= 1
TAG ?= $(APP_VERSION)-niceos$(NICEOS_STREAM)-r$(IMAGE_REVISION)
GO_RPM_NAME ?= go1.26

.PHONY: build test publish print-tag

print-tag:
	@echo $(IMAGE):$(TAG)

build:
	./scripts/build.sh

test:
	./scripts/test.sh $(IMAGE):$(TAG)

publish:
	./scripts/publish.sh $(IMAGE) $(TAG)

test-compat:
	IMAGE=$(IMAGE) ./tests/bitnami-compat-max.sh

test-compat-network:
	IMAGE=$(IMAGE) RUN_NETWORK_TESTS=1 ./tests/bitnami-compat-max.sh

test-compat-reference:
	IMAGE=$(IMAGE) REF_IMAGE=$(REF_IMAGE) RUN_NETWORK_TESTS=1 ./tests/bitnami-compat-max.sh
