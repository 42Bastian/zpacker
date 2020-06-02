	run $2000

ENDMARK EQU 1
a0 equ $10
a1 equ $12
src equ $14

	lda	#<pck
	sta	a0
	lda	#>pck
	sta	a0+1
	lda	#<(unpck-1)
	sta	a1
	lda	#>(unpck-1)
	sta	a1+1
	jsr	zdepack
.w
	bra	.w

zdepack::
	ldy	#1
	lda	(a0)
	cmp	#$c0
	bge	raw
	adc	#4
	tax
offset:
	lda	(a0),y

	adc	a1
	sta	src
	lda	a1+1
	adc	#$ff
	sta	src+1

cpylp:
	lda	(src),y
	sta	(a1),y
	iny
	dex
	bne	cpylp

	lda	#2
	bra	test

raw:
	and	#$3f
 IF ENDMARK = 1
	beq	done
 ENDIF
	tax
rawlp:
	lda	(a0),y
	sta	(a1),y
	iny
	dex
 IF ENDMARK = 1
	bne	rawlp
 ELSE
	bpl	rawlp
 ENDIF

	tya
test:
	clc
	adc	a0
	sta	a0
	bcc	.1
	inc	a0+1
.1

	clc
	dey
	tya
	adc	a1
	sta	a1
	bcc	.2
	inc	a1+1
.2
 IF ENDMARK = 1
	bra	zdepack
 ELSE
	lda	a0
	cmp	#<pck2
	lda	a0+1
	sbc	#>pck2
	bcc	zdepack
 ENDIF
zdepacke:
done:
	rts

size	equ zdepacke - zdepack
	echo "zdepack: %dsize"

pck::
	ibytes "test.txt.pck"
pck2::
	align $100
unpck:
	ds 1
