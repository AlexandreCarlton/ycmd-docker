IMAGE_NAME := alexandrecarlton/ycmd
YCMD_REVISION := 2f698d7

all: build

build:
	docker build \
		--build-arg=YCMD_REVISION=$(YCMD_REVISION) \
		--tag=$(IMAGE_NAME) \
		.
.PHONY: build
