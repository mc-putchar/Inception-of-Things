NAME := Inception-of-Things
AUTHORS := mcutura

SHELL := /bin/bash
ARCH := $(shell uname -m)

HOSTNAME := iot-host
SESSION := --connect qemu:///session
VM_NAME := IoT-host

VM_IMGDIR := ${HOME}/sgoinfre/VMs
VM_IMG := $(VM_IMGDIR)/iot.qcow2

ISO_DIR := ${HOME}/sgoinfre/iso

HOST_SSH_PORT := 2242

ifeq ($(ARCH), x86_64)
ISO_FILE := $(ISO_DIR)/ubuntu-22.04.5-live-server-amd64.iso
ISO_URL := https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
CLOUDIMG_FILE := $(ISO_DIR)/jammy-server-cloudimg-amd64.img
CLOUDIMG_URL := https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
else ifeq ($(ARCH),arm64)
ISO_FILE := $(ISO_DIR)/ubuntu-22.04.5-live-server-arm64.iso
ISO_URL := https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-arm64.iso
CLOUDIMG_FILE := $(ISO_DIR)/jammy-server-cloudimg-arm64.img
CLOUDIMG_URL := https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img
else
$(error Unsupported architecture: $(ARCH))
endif

VM_CLOUDIMG := $(VM_IMGDIR)/iot-cloud.qcow2

# Colors
RED := \033[31m
GRN := \033[32m
MAG := \033[35m
MAB := \033[1;35m
CYA := \033[36m
CYB := \033[1;36m
NC  := \033[0m

.PHONY: help

help:	# Show this helpful message
	@awk 'BEGIN { FS = ":.*#"; \
	printf "$(GRN)$(NAME)$(NC)\nby: $(AUTHORS)\t@$(GRN)42 Berlin$(NC)\n\n"; \
	printf "Usage:\n\t$(CYB)make $(MAG)<target>$(NC)\n" } \
	/^[A-Za-z_0-9-]+:.*?#/ { printf "$(MAB)%-16s $(CYA)%s$(NC)\n", $$1, $$2}' Makefile


##### VM xml import #####
.PHONY: start connect import clean

start:	# Start Host VM
	virsh $(SESSION) start $(VM_NAME)

stop:	# Stop Host VM
	virsh $(SESSION) destroy $(VM_NAME)

connect:	# Connect to Host VM
	virsh $(SESSION) console $(VM_NAME)

import: $(VM_IMG) | $(ISO_FILE)	# Import Host VM
	virsh $(SESSION) define --file <(sed "s|ISO_PATH|$(ISO_FILE)|g;s|PROJECT_DIR_PATH|$$(pwd)|g;s|INTRA_NAME|$${USER}|g" host/iot-host.xml)

$(ISO_FILE): | $(ISO_DIR)
	@curl -o $(ISO_FILE) $(ISO_URL)

$(VM_IMGDIR) $(ISO_DIR):
	@mkdir -p $@

$(VM_IMG): | $(VM_IMGDIR)
	qemu-img create -f qcow2 $(VM_IMG) 25G

clean:	# Remove Host VM and its storage
	$(info Cleaning up...)
	-virsh $(SESSION) destroy $(VM_NAME)
	-find ~/ -name "*$(VM_NAME)_VARS.fd*" -delete 2>/dev/null
	virsh $(SESSION) undefine $(VM_NAME) --snapshots-metadata --remove-all-storage


###### Cloud Init ######
.PHONY: install isofs

install: isofs $(VM_CLOUDIMG)	# Install VM from CloudImg
	virt-install $(SESSION) --name $(VM_NAME) --memory 8192 --vcpus 8 \
		--disk path=$(VM_CLOUDIMG),format=qcow2,bus=virtio \
		--disk path=host/seed.iso,device=cdrom,bus=sata \
		--filesystem $$(pwd),iot,type=mount,mode=squash \
		--os-variant ubuntu22.04 --network user --graphics none \
		--network none \
		--qemu-commandline="-netdev user,id=net0,hostfwd=tcp::$(HOST_SSH_PORT)-:22 -device virtio-net-pci,netdev=net0" \
		--console pty,target_type=serial \
		--boot hd,cdrom \
		--import \
		--noautoconsole

isofs:	# Create the Cloud-Init ISO
	sed "s|<HASH>|$$(openssl passwd -6)|g" host/user-data.yaml > host/user-data
	docker run --rm -v $(PWD)/host:/data alpine sh -c \
		"apk add --no-cache cdrkit && mkisofs -output /data/seed.iso -volid cidata -joliet -rock /data/user-data /data/meta-data"
	rm -f host/user-data

$(CLOUDIMG_FILE): | $(ISO_DIR)
	@curl -o $(CLOUDIMG_FILE) $(CLOUDIMG_URL)

$(VM_CLOUDIMG): $(CLOUDIMG_FILE) | $(VM_IMGDIR)
	qemu-img create -f qcow2 -b $(CLOUDIMG_FILE) -F qcow2 $(VM_CLOUDIMG) 25G
