#
# Copyright (2019) Petr Ospalý <petr@ospalax.cz>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

include Makefile.config

.PHONY: all clean install depend

all: $(BUILD_DIR)/$(LIBHOOK)

depend: $(BUILD_DIR)/.depend
$(BUILD_DIR)/.depend: $(SOURCE_FILES)
	@printf '\n# MAKE -> Find header files dependencies...\n\n'
	@mkdir -p "$(BUILD_DIR)"
	echo $(CPP) -MM $(SOURCE_FILES)
	$(CPP) -MM $(SOURCE_FILES) > "$(BUILD_DIR)"/.depend
	@sed -i "s#.*#${BUILD_DIR}/&#" "$(BUILD_DIR)"/.depend

include $(BUILD_DIR)/.depend

$(BUILD_DIR)/$(LIBHOOK): $(OBJECTS)
	@printf '\n# MAKE -> Build hook library: $@\n\n'
	@mkdir -p "$(BUILD_DIR)"
	$(CPP) $(CPPFLAGS) $(LIBS) -fpic -shared \
		-I "${KEA_INSTALLPREFIX}"/include/kea \
		-L "${KEA_INSTALLPREFIX}"/lib \
		$^ -o $@

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.cc
	@printf '\n# MAKE -> Build module: $@\n'
	@printf '          Dependencies: $^\n\n'
	@mkdir -p "$(BUILD_DIR)"
	$(CPP) $(CPPFLAGS) $(LIBS) -fpic -shared \
		-I "${KEA_INSTALLPREFIX}"/include/kea \
		-L "${KEA_INSTALLPREFIX}"/lib \
		-c $< -o $@

install: all
	@printf "\n# MAKE -> Copy hook library into Kea\n\n"
	@cp -av "$(BUILD_DIR)/$(LIBHOOK)" "${KEA_INSTALLPREFIX}"/lib/kea/hooks/
	@echo "${KEA_INSTALLPREFIX}/lib/kea/hooks/$(LIBHOOK)" \
		>> "${KEA_INSTALLPREFIX}/lib/kea/hooks/opennebula-hooks.list"
	@printf '\n# MAKE -> INSTALLATION DONE\n\n'

clean:
	@printf "\n# MAKE -> Delete all object files\n\n"
	@rm -vf "$(BUILD_DIR)/"*.o
	@printf '\n# MAKE -> CLEANUP DONE\n\n'
