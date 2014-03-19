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
		jne .dup

		call elementlen
		add bp, cx
		jmp mainloop

	.dup:
		cmp al, ':'
		jne .swap

		mov bx, bp
		call elementlen

		sub bp, cx
		mov di, bp

		call stack_memcpy

		jmp mainloop

	.swap:
		cmp al, '~'
		jne mainloop

		call elementlen

		; Move first element to a temporary location
		mov bx, bp
		mov di, bp
		sub di, cx
		call stack_memcpy

		; Save (ptr,len) of first element to (ax,dx)
		mov ax, di
		mov dx, cx

		; Move second element where first used to live
		mov di, bx
		add bp, cx
		mov bx, bp
		sub bp, cx
		call elementlen
		call stack_memcpy

		; Move first element where second used to live
		mov di, bx
		mov bx, ax
		mov dx, dx
		call stack_memcpy

		jmp mainloop

end:
	mov al, 10
	call putchar

	xor ax, ax
	mov ds, ax
	mov es, ax

	popa

	ret

; IN:
;	ES:BP -> pointer to stack element
; OUT:
;	CX -> length of element (counting the terminating NULL)
elementlen:
	push ax
	push bp

	mov dx, bp

	.loop:
		mov al, [es:bp]
		inc bp

		test al, al
		jnz .loop

	mov cx, bp
	sub cx, dx

	pop bp
	pop ax

	ret

; IN:
;	ES:BX -> source
;	ES:DI -> destination
;	CX    -> how many bytes to copy
stack_memcpy:
	pusha

	.loop:
		jcxz .end
		dec cx

		mov al, [es:bx]
		inc bx

		stosb

		jmp .loop
	.end:
		popa
		ret
