/* SPDX-License-Identifier: GPL-2.0-only */
/*
 *  linux/arch/arm/plat-versatile/headsmp.S
 *
 *  Copyright (c) 2003 ARM Limited
 *  All Rights Reserved
 */
#include <linux/linkage.h>
#include <linux/init.h>
#include <asm/assembler.h>

/*
 * Realview/Versatile Express specific entry point for secondary CPUs.
 * This provides a "holding pen" into which all secondary cores are held
 * until we're ready for them to initialise.
 */
ENTRY(versatile_secondary_startup)
 ARM_BE8(setend	be)
	mrc	p15, 0, r0, c0, c0, 5
	bic	r0, #0xff000000
	adr_l	r6, versatile_cpu_release
pen:	ldr	r7, [r6]
	cmp	r7, r0
	bne	pen

	/*
	 * we've been released from the holding pen: secondary_stack
	 * should now contain the SVC stack for this core
	 */
	b	secondary_startup
ENDPROC(versatile_secondary_startup)
