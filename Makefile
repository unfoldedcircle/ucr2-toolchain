#Makefile for the Unfolded Operating System project

BUILDDIR := $(shell pwd)
RELEASE_DIR = $(BUILDDIR)/release

BUILDROOT=$(BUILDDIR)/buildroot
BUILDROOT_EXTERNAL=$(BUILDDIR)/buildroot-external
DEFCONFIG_DIR = $(BUILDROOT_EXTERNAL)/configs

TARGETS := $(notdir $(patsubst %_defconfig,%,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_CONFIG := $(notdir $(patsubst %_defconfig,%-config,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_MENUCONFIG := $(notdir $(patsubst %_defconfig,%-menuconfig,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_LINUX_MENUCONFIG := $(notdir $(patsubst %_defconfig,%-linux-menuconfig,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_SDK := $(notdir $(patsubst %_defconfig,%-sdk,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_LEGAL_INFO := $(notdir $(patsubst %_defconfig,%-legal-info,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))

# Set O variable if not already done on the command line
ifneq ("$(origin O)", "command line")
O := $(BUILDDIR)/output
else
override O := $(BUILDDIR)/$(O)
endif

.NOTPARALLEL: $(TARGETS) $(TARGETS_CONFIG) $(TARGETS_MENUCONFIG) all

.PHONY: $(TARGETS) $(TARGETS_CONFIG) $(TARGETS_MENUCONFIG) $(TARGETS_SDK) $(TARGETS_LEGAL_INFO) all clean help

all: $(TARGETS)

$(RELEASE_DIR):
	mkdir -p $(RELEASE_DIR)

$(TARGETS_CONFIG): %-config:
	@echo "Board configuration: $*"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"

$(TARGETS): %: $(RELEASE_DIR) %-config
	@echo "Building board: $@"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL)
	@echo "Moving images to: $(RELEASE_DIR)"
	mv -f $(O)/images/uc-* $(RELEASE_DIR)/

	# Do not clean when building for one target
ifneq ($(words $(filter $(TARGETS),$(MAKECMDGOALS))), 1)
	@echo "Cleaning $@"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) clean
endif
	@echo "Finished building board: $@"

$(TARGETS_MENUCONFIG): %-menuconfig:
	@echo "menuconfig $*"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) menuconfig
	cp "$(DEFCONFIG_DIR)/$*_defconfig" "$(DEFCONFIG_DIR)/$*_defconfig.bak"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) BR2_DEFCONFIG="$(DEFCONFIG_DIR)/$*_defconfig" savedefconfig

$(TARGETS_LINUX_MENUCONFIG): %-linux-menuconfig:
	@echo "linux-menuconfig $*"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) linux-menuconfig
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) linux-update-defconfig

$(TARGETS_SDK): %-sdk:
	@echo "Building external toolchain for $*"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) sdk
	@echo "Moving SDK to: $(RELEASE_DIR)"
	mkdir -p $(RELEASE_DIR)
	mv -f $(O)/images/aarch64-buildroot-linux-gnu_sdk-buildroot.tar.gz $(RELEASE_DIR)/ucr2-aarch64-toolchain-$(shell $(BUILDROOT_EXTERNAL)/scripts/git-version.sh)-noqt.tar.gz

$(TARGETS_LEGAL_INFO): %-legal-info:
	@echo "Creating legal information for $*"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) "$*_defconfig"
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) legal-info

clean:
	$(MAKE) -C $(BUILDROOT) O=$(O) BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) clean


help:
	@echo "Supported targets: $(TARGETS)"
	@echo "Run 'make <target>' to build a target image and keep build artefacts."
	@echo "Run 'make all' to build all target images."
	@echo "Run 'make clean' to clean the build output."
	@echo "Run 'make <target>-config' to initialize buildroot for a target."
	@echo "Run 'make <target>-menuconfig' to configure a target."
	@echo "Run 'make <target>-sdk' to build the external toolchain."
	@echo "Run 'make <target>-legal-info' to gather licenses and create source tarballs."
