/* SPDX-License-Identifier: GPL-2.0 */

#include <asm/export.h>

#define NC_STORE_THRESHOLD	2048

#define SAVE_SIMD_REGS \
	ldi	$sp, -0x60($sp); \
	addl	$sp, 0x1f, $23; \
	bic	$23, 0x1f, $23; \
	vstd	$f1, 0($23); \
	vstd	$f2, 0x20($23)

#define RESTORE_SIMD_REGS \
	addl	$sp, 0x1f, $23; \
	bic	$23, 0x1f, $23; \
	vldd	$f1, 0($23); \
	vldd	$f2, 0x20($23); \
	ldi	$sp, 0x60($sp)

#define SAVE_SIMD_U_REGS \
	ldi	$sp, -0x120($sp); \
	addl	$sp, 0x1f, $23; \
	bic	$23, 0x1f, $23; \
	vstd	$f1, 0($23); \
	vstd	$f2, 0x20($23); \
	vstd	$f4, 0x40($23); \
	vstd	$f5, 0x60($23); \
	vstd	$f10, 0x80($23); \
	vstd	$f11, 0xa0($23); \
	vstd	$f20, 0xc0($23); \
	vstd	$f21, 0xe0($23)

#define RESTORE_SIMD_U_REGS \
	addl	$sp, 0x1f, $23; \
	bic	$23, 0x1f, $23; \
	vldd	$f1, 0($23); \
	vldd	$f2, 0x20($23); \
	vldd	$f4, 0x40($23); \
	vldd	$f5, 0x60($23); \
	vldd	$f10, 0x80($23); \
	vldd	$f11, 0xa0($23); \
	vldd	$f20, 0xc0($23); \
	vldd	$f21, 0xe0($23); \
	ldi	$sp, 0x120($sp)

	.set noat
	.align 4
	.globl memcpy
	.ent memcpy
memcpy:
	.frame $30, 0, $26, 0
	.prologue 0

	mov	$16, $0
	ble	$18, $out
	and	$16, 7, $1
	beq	$1, $dest_aligned_8

	.align 4
$byte_loop_head:
	ldbu	$2, 0($17)
	subl	$18, 1, $18
	addl	$17, 1, $17
	stb	$2, 0($16)
	addl	$16, 1, $16
	ble	$18, $out
	and	$16, 7, $1
	bne	$1, $byte_loop_head

$dest_aligned_8:
	and	$17, 7, $4
	subl	$18, 16, $18
	blt	$18, $quad_end
	subl	$18, 64, $18
	blt	$18, $simd_end
	and	$16, 31, $1
	beq	$1, $dest_aligned_32
	bne	$4, $quad_u_loop_head

	.align 5
$quad_loop_head:
	ldl	$2, 0($17)
	subl	$18, 8, $18
	addl	$17, 8, $17
	stl	$2, 0($16)
	addl	$16, 8, $16
	and	$16, 31, $1
	blt	$18, $simd_end
	beq	$16, $dest_aligned_32
	br	$31, $quad_loop_head

$dest_aligned_32:
	and	$17, 31, $5
	bne	$5, $prep_simd_u_loop

$prep_simd_loop:
	SAVE_SIMD_REGS
	ldi	$1, NC_STORE_THRESHOLD($31)
	cmple	$18, $1, $1
	bne	$1, $simd_loop

	.align 5
$simd_loop_nc:
	fillcs	128 * 5($17)
	vldd	$f1, 0($17)
	vldd	$f2, 32($17)
	subl	$18, 64, $18
	addl	$17, 64, $17
	vstd_nc	$f1, 0($16)
	vstd_nc	$f2, 32($16)
	addl	$16, 64, $16
	bge	$18, $simd_loop_nc
	memb			# required for _nc store instructions
	br	$31, $simd_loop_end

	.align 5
$simd_loop:
	fillcs	128 * 5($17)
	vldd	$f1, 0($17)
	vldd	$f2, 32($17)
	subl	$18, 64, $18
	addl	$17, 64, $17
	vstd	$f1, 0($16)
	vstd	$f2, 32($16)
	addl	$16, 64, $16
	bge	$18, $simd_loop

$simd_loop_end:
	addl	$18, 64, $1
	cmplt	$1, 32, $1
	bne	$1, $no_more_simd
	vldd	$f1, 0($17)
	subl	$18, 32, $18
	addl	$17, 32, $17
	vstd	$f1, 0($16)
	addl	$16, 32, $16

$no_more_simd:
	RESTORE_SIMD_REGS

$simd_end:
	addl	$18, 64, $18
	blt	$18, $quad_end
	bne	$4, $prep_quad_u_loop_tail

	.align 4
$quad_loop_tail:
	ldl	$2, 0($17)
	ldl	$3, 8($17)
	subl	$18, 16, $18
	addl	$17, 16, $17
	stl	$2, 0($16)
	stl	$3, 8($16)
	addl	$16, 16, $16
	bge	$18, $quad_loop_tail

$quad_end:
	addl	$18, 16, $18
	ble	$18, $out
	cmplt	$18, 8, $1
	bne	$1, $byte_loop_tail
	bne	$4, $move_one_quad_u

$move_one_quad:
	ldl	$2, 0($17)
	subl	$18, 8, $18
	addl	$17, 8, $17
	stl	$2, 0($16)
	addl	$16, 8, $16
	ble	$18, $out

	.align 4
$byte_loop_tail:
	ldbu	$2, 0($17)
	subl	$18, 1, $18
	addl	$17, 1, $17
	stb	$2, 0($16)
	addl	$16, 1, $16
	bgt	$18, $byte_loop_tail

$out:
	ret	$31, ($26), 1



	.align 5
$quad_u_loop_head:
	ldl_u	$2, 0($17)
	ldl_u	$3, 7($17)
	subl	$18, 8, $18
	addl	$17, 8, $17
	extll	$2, $4, $2
	exthl	$3, $4, $3
	bis	$2, $3, $2
	stl	$2, 0($16)
	addl	$16, 8, $16
	blt	$18, $simd_end
	beq	$16, $dest_aligned_32
	br	$31, $quad_u_loop_head

$prep_simd_u_loop:
	SAVE_SIMD_U_REGS
	andnot	$17, 31, $3
	ldi	$2, 256($31)
	sll	$5, 3, $1
	subl	$2, $1, $2
	sll	$1, 29, $1
	sll	$2, 29, $2
	ifmovd	$1, $f1
	ifmovd	$2, $f2
	vldd	$f4, 0($3)
	ldi	$1, NC_STORE_THRESHOLD($31)
	cmple	$18, $1, $1
	bne	$1, $simd_u_loop

	.align 5
$simd_u_loop_nc:
	vldd	$f5, 32($3)
	fillcs	128 * 5($3)
	srlow	$f4, $f1, $f10
	sllow	$f5, $f2, $f11
	vlogfc	$f10, $f11, $f31, $f10
	vldd	$f4, 64($3)
	srlow	$f5, $f1, $f20
	sllow	$f4, $f2, $f21
	vlogfc	$f20, $f21, $f31, $f20
	vstd_nc	$f10, 0($16)
	vstd_nc	$f20, 32($16)
	subl	$18, 64, $18
	addl	$3, 64, $3
	addl	$16, 64, $16
	bge	$18, $simd_u_loop_nc
	memb			# required for _nc store instructions
	br	$31, $simd_u_loop_end

	.align 5
$simd_u_loop:
	vldd	$f5, 32($3)
	fillcs	128 * 5($3)
	srlow	$f4, $f1, $f10
	sllow	$f5, $f2, $f11
	vlogfc	$f10, $f11, $f31, $f10
	vldd	$f4, 64($3)
	srlow	$f5, $f1, $f20
	sllow	$f4, $f2, $f21
	vlogfc	$f20, $f21, $f31, $f20
	vstd	$f10, 0($16)
	vstd	$f20, 32($16)
	subl	$18, 64, $18
	addl	$3, 64, $3
	addl	$16, 64, $16
	bge	$18, $simd_u_loop

$simd_u_loop_end:
	addl	$18, 64, $1
	cmplt	$1, 32, $1
	bne	$1, $no_more_simd_u
	vldd	$f5, 32($3)
	srlow	$f4, $f1, $f10
	sllow	$f5, $f2, $f11
	vlogfc	$f10, $f11, $f31, $f10
	vstd	$f10, 0($16)
	subl	$18, 32, $18
	addl	$3, 32, $3
	addl	$16, 32, $16

$no_more_simd_u:
	RESTORE_SIMD_U_REGS
	bis	$3, $5, $17
	br	$31, $simd_end

$prep_quad_u_loop_tail:
	ldl_u	$2, 0($17)
	.align 5
$quad_u_loop_tail:
	ldl_u	$3, 8($17)
	extll	$2, $4, $22
	exthl	$3, $4, $23
	bis	$22, $23, $22
	stl	$22, 0($16)
	ldl_u	$2, 16($17)
	extll	$3, $4, $24
	exthl	$2, $4, $25
	bis	$24, $25, $24
	stl	$24, 8($16)
	subl	$18, 16, $18
	addl	$17, 16, $17
	addl	$16, 16, $16
	bge	$18, $quad_u_loop_tail
	br	$31, $quad_end

$move_one_quad_u:
	ldl_u	$2, 0($17)
	ldl_u	$3, 8($17)
	subl	$18, 8, $18
	addl	$17, 8, $17
	extll	$2, $4, $22
	exthl	$3, $4, $23
	bis	$22, $23, $22
	stl	$22, 0($16)
	addl	$16, 8, $16
	ble	$18, $out
	br	$31, $byte_loop_tail

	.end memcpy
	EXPORT_SYMBOL(memcpy)
__memcpy = memcpy
.globl __memcpy
