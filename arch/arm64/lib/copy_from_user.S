/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (C) 2012 ARM Ltd.
 */

#include <linux/linkage.h>

#include <asm/asm-uaccess.h>
#include <asm/assembler.h>
#include <asm/cache.h>

/*
 * Copy from user space to a kernel buffer (alignment handled by the hardware)
 *
 * Parameters:
 *	x0 - to
 *	x1 - from
 *	x2 - n
 * Returns:
 *	x0 - bytes not copied
 */

	.macro ldrb1 reg, ptr, val
	user_ldst 9998f, ldtrb, \reg, \ptr, \val
	.endm

	.macro strb1 reg, ptr, val
	strb \reg, [\ptr], \val
	.endm

	.macro ldrh1 reg, ptr, val
	user_ldst 9997f, ldtrh, \reg, \ptr, \val
	.endm

	.macro strh1 reg, ptr, val
	strh \reg, [\ptr], \val
	.endm

	.macro ldr1 reg, ptr, val
	user_ldst 9997f, ldtr, \reg, \ptr, \val
	.endm

	.macro str1 reg, ptr, val
	str \reg, [\ptr], \val
	.endm

	.macro ldp1 reg1, reg2, ptr, val
	user_ldp 9997f, \reg1, \reg2, \ptr, \val
	.endm

	.macro stp1 reg1, reg2, ptr, val
	stp \reg1, \reg2, [\ptr], \val
	.endm

end	.req	x5
srcin	.req	x15
SYM_FUNC_START(__arch_copy_from_user)
	add	end, x0, x2
	mov	srcin, x1
#include "copy_template.S"
	mov	x0, #0				// Nothing to copy
	ret

/*
 * In feature CONFIG_ARM64_UCE_KERNEL_RECOVERY, if RAS error is triggered
 * in copy_from_user(), RAS error is processed in do_sea() and
 * copy_from_user_sea_fallback will be assigned to regs->pc, finally return
 * here to continue processing.
 */
	.global copy_from_user_sea_fallback
copy_from_user_sea_fallback:
	sub	x0, end, dst			// bytes not copied
	ret
SYM_FUNC_END(__arch_copy_from_user)
EXPORT_SYMBOL(__arch_copy_from_user)

	.section .fixup,"ax"
	.align	2
9997:	cmp	dst, dstin
	b.ne	9998f
	// Before being absolutely sure we couldn't copy anything, try harder
USER(9998f, ldtrb tmp1w, [srcin])
	strb	tmp1w, [dst], #1
9998:	sub	x0, end, dst			// bytes not copied
	ret
	.previous
