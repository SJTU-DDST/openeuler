# SPDX-License-Identifier: GPL-2.0
#
# sw/Makefile
#
# This file is subject to the terms and conditions of the GNU General Public
# License.  See the file "COPYING" in the main directory of this archive
# for more details.
#
# Copyright (C) 1994 by Linus Torvalds
#

archscripts: scripts_basic
	$(Q)$(MAKE) $(build)=arch/sw_64/tools relocs

archheaders:
	$(Q)$(MAKE) $(build)=arch/sw_64/kernel/syscalls all

NM := $(NM) -B
CCVERSION := $(shell $(CC) -dumpversion)
LDFLAGS_vmlinux	:= -static -N #-relax
CHECKFLAGS	+= -D__sw__

ifeq ($(CONFIG_RELOCATABLE),y)
LDFLAGS_vmlinux                        += --emit-relocs
endif

CHECKFLAGS	+= -D__sw__
cflags-y	:= -pipe -ffixed-8 -mno-fp-regs #-msmall-data
cflags-y	+= $(call cc-option, -fno-jump-tables)

cflags-y				+= $(cpuflags-y)

KBUILD_CFLAGS += $(cflags-y)
KBUILD_DEFCONFIG = defconfig

head-y := arch/sw_64/kernel/head.o

core-y				+= arch/sw_64/kernel/ arch/sw_64/mm/
core-y				+= arch/sw_64/platform/
core-y				+= arch/sw_64/chip/
core-$(CONFIG_MATHEMU)		+= arch/sw_64/math-emu/
drivers-$(CONFIG_OPROFILE)	+= arch/sw_64/oprofile/
libs-y				+= arch/sw_64/lib/
core-$(CONFIG_KVM)		+= arch/sw_64/kvm/
core-$(CONFIG_SW64_BUILTIN_DTB)	+= arch/sw_64/boot/dts/
core-$(CONFIG_NET)		+= arch/sw_64/net/

# export what is needed by arch/sw_64/boot/Makefile
LIBS_Y := $(patsubst %/, %/lib.a, $(libs-y))
export LIBS_Y

boot := arch/sw_64/boot

#Default target when executing make with no arguments
all: $(boot)/vmlinux.bin.gz

$(boot)/vmlinux.bin.gz: vmlinux
	$(Q)$(MAKE) $(build)=$(boot) $@

bootimage bootpfile bootpzfile: vmlinux
	$(Q)$(MAKE) $(build)=$(boot) $(boot)/$@

archclean:
	$(Q)$(MAKE) $(clean)=$(boot)
	$(Q)$(MAKE) $(clean)=arch/sw_64/tools

KBUILD_IMAGE := $(boot)/vmlinux.bin

define archhelp
  echo '* boot		- Compressed kernel image (arch/sw_64/boot/vmlinux.bin.gz)'
endef
