APP ?= nginx
APP_VERSION ?= 1.31.1
NICEOS_VERSION ?= 13
IMAGE_REVISION ?= 1
IMAGE ?= docker.io/niceos/$(APP)
GHCR_IMAGE ?= ghcr.io/niceos-containers/$(APP)
IMMUTABLE_TAG := $(APP_VERSION)-niceos$(NICEOS_VERSION)-r$(IMAGE_REVISION)

.PHONY: build test smoke compat push release update sync-monorepo clean

build:
	podman build --format docker --no-cache 		--build-arg NICEOS_VERSION=$(NICEOS_VERSION) 		--build-arg APP_VERSION=$(APP_VERSION) 		--build-arg IMAGE_REVISION=$(IMAGE_REVISION) 		-t $(IMAGE):$(IMMUTABLE_TAG) 		-t $(IMAGE):$(APP_VERSION) 		-t $(IMAGE):latest .

smoke:
	./tests/smoke.sh $(IMAGE):$(IMMUTABLE_TAG)

compat:
	./tests/bitnami-contract-smoke.sh $(IMAGE):$(IMMUTABLE_TAG)

test: smoke compat
	./tests/local-compat-suite.sh $(IMAGE):$(IMMUTABLE_TAG)

push:
	podman push $(IMAGE):$(IMMUTABLE_TAG)
	podman push $(IMAGE):$(APP_VERSION)
	podman push $(IMAGE):latest
	podman tag $(IMAGE):$(IMMUTABLE_TAG) $(GHCR_IMAGE):$(IMMUTABLE_TAG)
	podman tag $(IMAGE):$(IMMUTABLE_TAG) $(GHCR_IMAGE):$(APP_VERSION)
	podman tag $(IMAGE):$(IMMUTABLE_TAG) $(GHCR_IMAGE):latest
	podman push $(GHCR_IMAGE):$(IMMUTABLE_TAG)
	podman push $(GHCR_IMAGE):$(APP_VERSION)
	podman push $(GHCR_IMAGE):latest

release:
	./scripts/niceos_app_release_nginx.py release $(APP_VERSION) --revision $(IMAGE_REVISION) --niceos-version $(NICEOS_VERSION) -y

update:
	./scripts/niceos_app_release_nginx.py update $(APP_VERSION) --revision $(IMAGE_REVISION) --niceos-version $(NICEOS_VERSION) -y

sync-monorepo:
	./scripts/niceos_app_release_nginx.py update $(APP_VERSION) --revision $(IMAGE_REVISION) --niceos-version $(NICEOS_VERSION) --refresh-monorepo-only -y

clean:
	rm -rf build dist work artifacts reports tmp .cache
