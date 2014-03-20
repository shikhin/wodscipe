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
		jne .enclose

		; Move first element to a temporary location
		call elementlen
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
		call elementlen
		xchg bx, bp
		call stack_memcpy

		; Move first element after where the second element now is
		mov di, bp
		add di, cx
		mov bx, ax
		mov cx, dx
		call stack_memcpy

		jmp mainloop

	.enclose:
		cmp al, 'a'
		jne .exec

		; Shift down one to provide space for ending bracket
		call elementlen
		mov bx, bp
		dec bp
		mov di, bp
		call stack_memcpy

		; Starting bracket
		dec bp
		mov byte [es:bp], '('

		; Ending bracket
		mov bx, bp
		add bx, cx
		mov byte [es:bx], ')'

		; NOTE: it will be already null-terminated as it was copied down by one, leaving original terminator after end of element

		jmp mainloop

	.exec:
		cmp al, '^'
		jne mainloop

		call elementlen
		sub si, cx
		inc si
		mov bx, si

		.exec_copyloop:
			mov al, [es:bp]
			inc bp

			test al, al
			jz .exec_end

			mov [bx], al
			inc bx

			jmp .exec_copyloop
		.exec_end:
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
