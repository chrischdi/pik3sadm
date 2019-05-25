DOCKER_IMAGE_NAME ?= pik3s
DOCKER_IMAGE_TAG  ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))-$(shell date +%Y-%m-%d)-$(shell git rev-parse --short HEAD)

ARCHLINUX_ARCH ?= aarch64
ARCHLINUX_URL ?= http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-3-latest.tar.gz
ARCHLINUX_TAR ?= ArchLinuxARM-rpi-3-latest.tar.gz
ARCHLINUX_QEMU ?= qemu-aarch64-static
# ARCHLINUX_CC_URL ?= https://archlinuxarm.org/builder/xtools/x-tools7h.tar.xz

tmp/image.tar.gz: docker
	docker create --name $(DOCKER_IMAGE_NAME)-$(ARCHLINUX_ARCH) --entrypoint /bin/sh $(DOCKER_IMAGE_NAME):$(ARCHLINUX_ARCH)
	docker export $(DOCKER_IMAGE_NAME)-$(ARCHLINUX_ARCH) > tmp/image.tar.gz
	docker rm $(DOCKER_IMAGE_NAME)-$(ARCHLINUX_ARCH)

docker: deps
	mkdir -p bin
	@echo ">> building rpi image for $(ARCHLINUX_ARCH)"
	docker build \
	--build-arg rootfs_tar=tmp/$(ARCHLINUX_TAR) \
	--build-arg qemu_binary=tmp/$(ARCHLINUX_QEMU) \
	-t $(DOCKER_IMAGE_NAME):$(ARCHLINUX_ARCH) .

deps:
	echo ">> creating directory tmp"
	mkdir -p tmp
	echo ">> downloading archlinux $(ARCHLINUX_ARCH) image"
	wget -c $(ARCHLINUX_URL) -O tmp/$(ARCHLINUX_TAR)
	echo ">> copying $(ARCHLINUX_QEMU) binary"
	cp $(shell which $(ARCHLINUX_QEMU)) ./tmp/

clean:
	rm -rf ./tmp ./bin