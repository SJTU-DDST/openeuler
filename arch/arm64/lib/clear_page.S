/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (C) 2012 ARM Ltd.
 */

#include <linux/linkage.h>
#include <linux/const.h>
#include <asm/assembler.h>
#include <asm/page.h>
#include <asm/alternative.h>

/*
 * Clear page @dest
 *
 * Parameters:
 *	x0 - dest
 */
SYM_FUNC_START(clear_page_stnp)
	.align	6
1:	stnp xzr, xzr, [x0]
	stnp xzr, xzr, [x0, #0x10]
	stnp xzr, xzr, [x0, #0x20]
	stnp xzr, xzr, [x0, #0x30]
	add	x0, x0, #0x40
	tst	x0, #(PAGE_SIZE - 1)
	b.ne	1b
	ret
SYM_FUNC_END(clear_page_stnp)

/*
 * Clear page @dest
 *
 * Parameters:
 *	x0 - dest
 */
SYM_FUNC_START(clear_page)
	ALTERNATIVE("nop", "b clear_page_stnp", ARM64_CLEARPAGE_STNP)

	mrs	x1, dczid_el0
	and	w1, w1, #0xf
	mov	x2, #4
	lsl	x1, x2, x1

1:	dc	zva, x0
	add	x0, x0, x1
	tst	x0, #(PAGE_SIZE - 1)
	b.ne	1b
	ret
SYM_FUNC_END(clear_page)
EXPORT_SYMBOL(clear_page)
