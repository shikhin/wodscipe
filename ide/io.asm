; IN:
;	AL -> char to output
putchar:
	pusha

	mov ah, 0xE
	int 0x10

	cmp al, 10
	jne .end

	mov al, 13
	int 0x10

	.end:
		popa
		ret

; IN:
;	SI -> null-terminated string
puts:
	pusha

	.loop:
		lodsb
		cmp al, 0
		je .end

		call putchar

		jmp .loop

	.end:
		popa
		ret

; OUT:
;	AL -> inputted char, unix new lines.
;	AH -> BIOS scan code for char
getch:
	xor ax, ax
	int 0x16

	cmp al, 13
	jne .end

	.newline:
		mov al, 10
	.end:
		ret

; IN:
;	DI -> buffer
;	CX -> length of buffer
; OUT:
;	AX -> chars read
; NOTE: do _not_ pass 0-byte buffers
getline:
	pusha

	dec cx
	xor bx, bx

	.readloop:
		call getch

		; Delete the last character.
		cmp al, 8
		je .delete

		cmp al, 10
		je .end

		cmp bx, cx
		je .readloop

		call putchar
		stosb
		inc bx

		jmp .readloop

		.delete:
			test bx, bx
			jz .readloop

			mov si, .del_string
			call puts

			dec bx
			dec di

			jmp .readloop

		.del_string: db 8, ' ', 8, 0

	.end:
		call putchar
		xor al, al
		stosb

		; STORE AX.
		mov [esp + 14], bx

		popa
		ret
