IMAGE_NAME := alexandrecarlton/ycmd
YCMD_REVISION := 9c9ef18

VCS_REF := $(shell git rev-parse --short HEAD)

all: image

image: ycmd-image.tar
.PHONY: image

ycmd-image.tar:
	docker build \
		--build-arg=YCMD_REVISION=$(YCMD_REVISION) \
		--label org.label-schema.build-date="$(shell date --rfc-3339=seconds)" \
		--label org.label-schema.name="ycmd" \
		--label org.label-schema.description="A docker image containing ycmd for YouCompleteMe" \
		--label org.label-schema.url="https://github.com/AlexandreCarlton/ycmd-docker" \
		--label org.label-schema.vcs-url="https://github.com/AlexandreCarlton/ycmd-docker" \
		--label org.label-schema.vcs-ref="$(VCS_REF)" \
		--label org.label-schema.version="$(YCMD_REVISION)" \
		--label org.label-schema.schema-version="1.0" \
		--tag=$(IMAGE_NAME):build \
		.
	docker save --output="ycmd-image.tar" $(IMAGE_NAME):build
.PHONY: image

push: ycmd-image.tar
	docker load --input="ycmd-image.tar"
	docker tag $(IMAGE_NAME):build $(IMAGE_NAME):$(VCS_REF)
	docker tag $(IMAGE_NAME):build $(IMAGE_NAME):$(YCMD_REVISION)
	docker tag $(IMAGE_NAME):build $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):$(VCS_REF)
	docker push $(IMAGE_NAME):$(YCMD_REVISION)
	docker push $(IMAGE_NAME):latest
.PHONY: push

test: ycmd-image.tar
	docker load --input="ycmd-image.tar"
	# Point to our newly built image when testing.
	sed -ri 's|(alexandrecarlton/ycmd)|\1:build|' ycmd-python
	python3 tests/example_client.py
.PHONY: test
