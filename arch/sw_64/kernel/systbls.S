/* SPDX-License-Identifier: GPL-2.0 */
/*
 * arch/sw_64/kernel/systbls.S
 *
 * The system call table.
 */

#include <asm/unistd.h>

#define __SYSCALL(nr, entry, nargs) .quad entry
	.data
	.align 3
	.globl sys_call_table
sys_call_table:
#include <asm/syscall_table.h>
#undef __SYSCALL
