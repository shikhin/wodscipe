%include "wodscipe.inc"
org 0x7E00

start:
	pusha

	; Set up temporary segment
	mov ax, 0x1000
	mov es, ax

	; Source stack (ds:si)
	mov cx, [0x8000]

	mov si, 0x8002

	xor di, di
	sub di, cx
	mov dx, di ; Save

	rep movsb

	mov si, dx

	; Real segments
	mov ax, 0x1000
	mov ds, ax

	shl ax, 1
	mov es, ax

	; Data stack (es:bp)
	xor bp, bp

mainloop:
	test si, si
	jz end

	lodsb

	.bracket:
		cmp al, '('
		jne .print

		mov dx, si ; Save start of quoted expression

		mov cx, 1
		.bracketloop:
			lodsb

			cmp al, ')'
			je .shallower
			cmp al, '('
			jne .bracketloop
			
			.deeper:
				inc cx
				jmp .bracketloop
			.shallower:
				dec cx
				jnz .bracketloop

		dec si
		mov byte [si], 0

		; Len=end-start+1
		mov cx, si
		sub cx, dx
		inc cx

		mov si, dx

		mov di, bp
		sub di, cx
		mov dx, di ; Save new data stack pointer

		rep movsb

		mov bp, dx ; Restore data stack pointer

		jmp mainloop

	.print:
		cmp al, 'S'
		jne .drop

		.printloop:
			mov al, [es:bp]
			inc bp

			test al, al
			jz mainloop

			call putchar

			jmp .printloop

	.drop:
		cmp al, '!'
		jne mainloop

		.droploop:
			mov al, [es:bp]
			inc bp

			test al, al
			jz mainloop

			jmp .droploop

end:
	mov al, 10
	call putchar

	xor ax, ax
	mov ds, ax
	mov es, ax

	popa

	ret
