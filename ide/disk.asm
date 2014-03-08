%define SECTORS_PER_TRACK   18
%define HEADS               2
%define TRACKS              80

; IN:
;	AX -> LBA
;	BX -> buffer
;	DI -> 0 for read, (1 << 8) for write
rwsector:
	pusha

	; Three tries.
	mov si, 3

	; Get CHS.
	; CH  -> cylinder number.
	; CL  -> sector number.
	; DH  -> head number.
	xor dx, dx
	mov cx, SECTORS_PER_TRACK
	div cx

	; Get sector.
	mov cl, dl
	inc cl

	; Get head number.
	mov dh, al
	and dh, 0x1

	; Get track number.
	shr ax, 1
	mov ch, al

	mov dl, [BOOTDEV]

	.loop:
		; Prepare for interrupt.
		mov ax, 0x0201
		add ax, di

		int 0x13

		; If successful, return.
		jnc .return

		; Else, try to reset.
		xor ah, ah
		int 0x13

		dec si
		jnz .loop

	.error:
		jmp panic

	.return:
		popa
		ret
