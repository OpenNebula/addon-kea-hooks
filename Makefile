#
# Copyright (2019) Petr Ospalý <petr@ospalax.cz>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

# make config file - it provides default values
include Makefile.config

.PHONY: all docker image package clean

all: docker image package

image: $(BUILD_DIR)/$(IKEA_IMG)-$(KEA_VERSION).tar
package: $(BUILD_DIR)/$(IKEA_PKG)-$(KEA_VERSION).tar.xz

$(BUILD_DIR)/$(IKEA_PKG)-$(KEA_VERSION).tar.xz: docker
	@echo "IKEA: CREATE PACKAGE..."
	docker run --rm -it --entrypoint /bin/sh \
		-e "KEA_INSTALLPREFIX=$(KEA_INSTALLPREFIX)" \
		-e "IKEA_PKG=$(IKEA_PKG)" \
		-e "KEA_VERSION=$(KEA_VERSION)" \
		-e "UID_GID=$$(getent passwd $$(id -u) | cut -d":" -f3,4)" \
		-v "$$(realpath '$(BUILD_DIR)'):/build/:rw" \
		-v "$$(realpath ./tools/arkea.sh):/arkea.sh:ro" \
		--user root \
		$(IKEA_TAG):$(KEA_VERSION) \
		/arkea.sh
	cd "$(BUILD_DIR)" && \
		sha256sum "$(IKEA_PKG)-$(KEA_VERSION).tar.xz" \
			> "$(IKEA_PKG)-$(KEA_VERSION).tar.xz.sha256sum"

$(BUILD_DIR)/$(IKEA_IMG)-$(KEA_VERSION).tar: docker
	@echo "IKEA: SAVE DOCKER IMAGE INTO TAR..."
	docker save -o "$(BUILD_DIR)/$(IKEA_IMG)-$(KEA_VERSION).tar" \
		$(IKEA_TAG):$(KEA_VERSION)

docker: Dockerfile ikea.sh
	@echo "IKEA: START DOCKER BUILD..."
	@mkdir -p "$(BUILD_DIR)"
	@if [ -f "$(BUILD_DIR)/$(IKEA_TAG)-$(KEA_VERSION)-build.log" ] ; then \
		mv -vf "$(BUILD_DIR)/$(IKEA_TAG)-$(KEA_VERSION)-build.log" \
		"$(BUILD_DIR)/$(IKEA_TAG)-$(KEA_VERSION)-build.log.old" ; \
		fi
	docker build -t $(IKEA_TAG):$(KEA_VERSION) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg KEA_VERSION=$(KEA_VERSION) \
		--build-arg KEA_INSTALLPREFIX="$(KEA_INSTALLPREFIX)" \
		--build-arg MAKE_JOBS=$(MAKE_JOBS) \
		--build-arg KEEP_BUILDBLOB=$(KEEP_BUILDBLOB) \
		--build-arg KEEP_BUILDDEPS=$(KEEP_BUILDDEPS) \
		--build-arg INSTALL_HOOKS=$(INSTALL_HOOKS) \
		. | tee "$(BUILD_DIR)/$(IKEA_TAG)-$(KEA_VERSION)-build.log"

clean:
	@echo "IKEA: DELETE BUILD DIR"
	rm -rf "$(BUILD_DIR)"

