//---------------------------------------------------------------------
//	zdepack
//	by zerkman / Sector One
//---------------------------------------------------------------------

// Copyright (c) 2020 Francois Galea <fgalea at free.fr>
// This program is free software. It comes without any warranty, to
// the extent permitted by applicable law. You can redistribute it
// and/or modify it under the terms of the Do What The Fuck You Want
// To Public License, Version 2, as published by Sam Hocevar. See
// the COPYING file or http://www.wtfpl.net/ for more details.

// unpack data chunk
// parameters:
// a0: beginning of packed data
// a1: unpack buffer
// a2: end of packed data
// returned value:
// a1: end of unpacked data
	.text
ENDMARK = 1

//->	move.l	#0x100000,a0
//->	lea	end(pc),a1
//->	lea	1000(a0),a2
 .if ENDMARK == 1
zdepack:

offset:	move.b	(a0)+,d1	// offset
	addq.b	#3,d0		// size

offlp:	move.b	(a1,d1.w),(a1)+
	subq.b	#1,d0
	bcc.s	offlp
next:
	move.b	(a0)+,d0
	moveq	#0xffffffc0,d1
	eor.b	d0,d1
	lsr.b	#6,d1
	bne.s	offset

raw:	lsl.b	#2,d0
	beq.s	end
rawlp:	move.b	(a0)+,(a1)+
	subq.b	#4,d0
	bne.s	rawlp
	bra.s	next
end:
 .else
zdepack:
next:
	move.b	(a0)+,d0
	moveq	#0xffffffc0,d1
	eor.b	d0,d1
	lsr.b	#6,d1
	bne.s	offset

raw:	lsl.b	#2,d0		// size*4
rawlp:	move.b	(a0)+,(a1)+
	subq.b	#4,d0
	bcc.s	rawlp
	bra.s	test

offset:	move.b	(a0)+,d1	// offset
	addq.b	#3,d0		// size

offlp:	move.b	(a1,d1.w),(a1)+
	subq.b	#1,d0
	bcc.s	offlp

test:	cmp.l	a2,a0
	bne.s	next
 .endif
end:
