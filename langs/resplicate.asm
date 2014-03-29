%include "wodscipe.inc"
org 0x7E00
numimp_flag equ 0x504

start:
	pusha
	push es

	; Segment
	mov ax, 0x1000
	mov es, ax

	; Ring buffer
	mov bp, 0 ; Origin
	mov di, 0 ; Size

parse_setup:
	; Source
	mov si, 0x8002
	mov cx, [0x8000]

	; Number input
	xor dx, dx
	mov byte [numimp_flag], 0

; NOTE: parser relies on the final newline being there, as unless it would in some cases not store the last num
parse:
	jcxz run

	lodsb
	dec cx

	cmp al, '0'
	jb .notdigit
	
	cmp al, '9'
	ja .notdigit

	.digit:
		; Multiply dx by 10
		mov bx, dx
		shl dx, 3
		shl bx, 1
		add dx, bx

		; Add the new digit
		xor ah, ah
		sub al, '0'
		add dx, ax

		mov byte [numimp_flag], 1

		jmp parse

	.notdigit:
		cmp byte [numimp_flag], 0
		je parse

		; Find end of ring buffer and expand it by 2 bytes and save inputted number
		mov bx, di
		add di, 2
		mov [es:bx], dx

		; Reset the number input state
		xor dx, dx
		mov byte [numimp_flag], 0

		jmp parse

run:
	cmp di, 0
	je end

	mov bx, [es:bp]
	mov cx, [es:bp+2]
	add bp, 4
	sub di, 4

	cmp bx, 0
	je .io

	shl bx, 1
	; bx>di
	mov si, bp
	add si, di
	.addzeros:
		cmp bx, di
		jle .copyloop

		mov byte [es:si], 0
		inc si
		inc di

		jmp .addzeros

	; Copy bx bytes cx times
	.copyloop:
		jcxz .copyend

		call copybytes
		add di, bx
		dec cx

		jmp .copyloop

	.copyend:
		add bp, bx
		sub di, bx
		jmp run

	.io:
		; TODO: IO
		cmp cx, 0
		jl .in

		.out:
			mov al, cl
			call putchar
			jmp run

		.in:
			jmp run

end:
	pop es
	popa
	xor al, al
	ret

; IN:
;	BP    -> ring buffer start, source
;	DI    -> len of ring buffer
;	BP+DI -> destination
;	BX    -> how many bytes to copy
copybytes:
	pusha

	mov cx, bx
	add di, bp

	.loop:
		jcxz .end
		dec cx

		mov al, [es:bp]
		inc bp
		stosb

		jmp .loop

	.end:
		popa
		ret

%include "hexprint.inc"
