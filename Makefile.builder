ifeq ($(DIST),archlinux)
    ARCHLINUX_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := archlinux
    BUILDER_MAKEFILE = $(ARCHLINUX_PLUGIN_DIR)Makefile.archlinux
    TEMPLATE_SCRIPTS = $(ARCHLINUX_PLUGIN_DIR)scripts_archlinux
endif

# vim: ft=make
