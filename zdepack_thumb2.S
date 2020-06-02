// !!! UNTESTED !!!

	.text

// r0 - packed data
// r1 - end of packed data (first byte after)
// r2 - unpacked data

	.syntax unified
	.globl	zdepack
	.thumb
	.thumb_func

zdepack:
	push	{r4-r5,lr}
loop:
	ldrb	r3,[r0],#1
	cmp	r3,#0xc0
	bhs	raw
offset:
	ldrsb	r5,[r0],#1
	adds	r3,r3,#4
cpylp:
	ldrb	r4,[r2,r5]
	strb	r4,[r2],#1
	subs	r3,r3,#1
	bne	cpylp
	b	test
raw:
	lsls	r3,r3,#2
rawlp:
	ldrb	r4,[r0],#1
	strb	r4,[r2],#1
	subs	r3,r3,#4
	bpl	rawlp
test:
	cmp	r0,r1
	bne	loop
done:
	pop	{r4-r5,pc}
