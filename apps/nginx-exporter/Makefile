APP ?= nginx-exporter
APP_VERSION ?= 1.5.1
NICEOS_VERSION ?= 13
IMAGE_REVISION ?= 1
IMAGE ?= docker.io/niceos/$(APP)
GHCR_IMAGE ?= ghcr.io/niceos-containers/$(APP)
CONTAINER_ENGINE ?= podman
IMMUTABLE_TAG := $(APP_VERSION)-niceos$(NICEOS_VERSION)-r$(IMAGE_REVISION)

.PHONY: build smoke compat test compare helm-metrics push release update sync-monorepo clean shell

build:
	$(CONTAINER_ENGINE) build --format docker --no-cache \
		--build-arg NICEOS_VERSION=$(NICEOS_VERSION) \
		--build-arg APP_VERSION=$(APP_VERSION) \
		--build-arg IMAGE_REVISION=$(IMAGE_REVISION) \
		-t $(IMAGE):$(IMMUTABLE_TAG) \
		-t $(IMAGE):$(APP_VERSION) \
		-t $(IMAGE):latest .

smoke:
	./tests/smoke.sh $(IMAGE):$(IMMUTABLE_TAG)

compat:
	./tests/bitnami-contract-smoke.sh $(IMAGE):$(IMMUTABLE_TAG)

compare:
	./tests/compare-with-bitnami.sh $(IMAGE):$(IMMUTABLE_TAG)

helm-metrics:
	./tests/helm-nginx-chart-metrics-smoke.sh ../chart-nginx/chart $(IMAGE):$(IMMUTABLE_TAG)

test: smoke compat
	./tests/local-compat-suite.sh $(IMAGE):$(IMMUTABLE_TAG)

push:
	$(CONTAINER_ENGINE) push $(IMAGE):$(IMMUTABLE_TAG)
	$(CONTAINER_ENGINE) push $(IMAGE):$(APP_VERSION)
	$(CONTAINER_ENGINE) push $(IMAGE):latest
	$(CONTAINER_ENGINE) tag $(IMAGE):$(IMMUTABLE_TAG) $(GHCR_IMAGE):$(IMMUTABLE_TAG)
	$(CONTAINER_ENGINE) tag $(IMAGE):$(IMMUTABLE_TAG) $(GHCR_IMAGE):$(APP_VERSION)
	$(CONTAINER_ENGINE) tag $(IMAGE):$(IMMUTABLE_TAG) $(GHCR_IMAGE):latest
	$(CONTAINER_ENGINE) push $(GHCR_IMAGE):$(IMMUTABLE_TAG)
	$(CONTAINER_ENGINE) push $(GHCR_IMAGE):$(APP_VERSION)
	$(CONTAINER_ENGINE) push $(GHCR_IMAGE):latest

release:
	./scripts/niceos_app_release_nginx_exporter.py release $(APP_VERSION) \
		--revision $(IMAGE_REVISION) \
		--niceos-version $(NICEOS_VERSION) \
		-y

update:
	./scripts/niceos_app_release_nginx_exporter.py update $(APP_VERSION) \
		--revision $(IMAGE_REVISION) \
		--niceos-version $(NICEOS_VERSION) \
		-y

sync-monorepo:
	./scripts/niceos_app_release_nginx_exporter.py update $(APP_VERSION) \
		--revision $(IMAGE_REVISION) \
		--niceos-version $(NICEOS_VERSION) \
		--refresh-monorepo-only \
		-y

shell:
	$(CONTAINER_ENGINE) run --rm -it --entrypoint /bin/bash $(IMAGE):$(IMMUTABLE_TAG)

clean:
	rm -rf build dist work artifacts reports tmp .cache
