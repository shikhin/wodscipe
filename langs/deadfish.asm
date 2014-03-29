%include "wodscipe.inc"
org 0x7E00

start:
	pusha

	; Source
	mov si, 0x8002
	mov di, [0x8000]
	add di, 0x8002

	; Accumulator
	xor dx, dx

mainloop:
	cmp si, di
	je .end

	cmp dx, -1
	je .zero
	cmp dx, 256
	je .zero

	lodsb

	cmp al, 'i'
	je .inc
	cmp al, 'x'
	je .inc

	cmp al, 'd'
	je .dec

	cmp al, 's'
	je .square
	cmp al, 'k'
	je .square
	
	cmp al, 'o'
	je .output
	cmp al, 'c'
	je .output

	jmp mainloop

.zero:
	xor dx, dx
	jmp mainloop

.inc:
	inc dx
	jmp mainloop

.dec:
	dec dx
	jmp mainloop

.square:
	mov ax, dx
	mov bx, dx
	mul bx
	mov dx, ax
	jmp mainloop

.output:
	push dx

	mov bp, 0x55A
	mov byte [bp], 0

	mov ax, dx
	mov bx, 10

	.outputloop:
		xor dx, dx
		div bx

		add dl, '0'
		dec bp
		mov [bp], dl

		cmp ax, 0
		jne .outputloop

	xchg si, bp
	call puts
	xchg si, bp

	mov al, ' '
	call putchar

	pop dx
	jmp mainloop

.end:
	mov al, 10
	call putchar

	popa
	xor al, al
	ret
