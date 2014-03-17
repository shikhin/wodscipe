%include "wodscipe.inc"
org 0x3000

reloc:
	pusha

	mov si, 0x7E00
	mov di, reloc
	mov cx, 0x200
	rep movsb

	jmp 0x0000:start

start:

	popa
	ret
