%include "wodscipe.inc"
org 0x7E00

numinp_flag EQU 0x504

%macro bppush 1
	sub bp, 2
	mov [es:bp], %1
%endmacro

%macro bppop 1
	mov %1, [es:bp]
	add bp, 2
%endmacro

main:
	pusha
	push es

	; Stack
	xor bp, bp
	mov ax, 0x1000
	mov es, ax

	; Number input
	xor dx, dx

	; Code
	lea si, [bx + 2]
	mov cx, si
	add cx, [bx]

	.mainloop:
		cmp si, cx
		je end

		lodsb

		.num:
			.num09:
				cmp al, '0'
				jb .notnum
				cmp al, '9'
				ja .numAF

				sub al, '0'
				jmp .storenum

			.numAF:
				cmp al, 'A'
				jb .notnum
				cmp al, 'F'
				ja .numaf

				sub al, 'A'-10
				jmp .storenum

			.numaf:
				cmp al, 'a'
				jb .notnum
				cmp al, 'f'
				ja .notnum

				sub al, 'a'-10

			.storenum:
				shl dx, 4
				xor ah, ah
				add dx, ax

				mov byte [numinp_flag], 1

				jmp .mainloop
		.notnum:
			cmp byte [numinp_flag], 0
			je .print

			bppush dx

			; Unset number input flag and clear dx for next use
			mov byte [numinp_flag], 0
			xor dx, dx

		.print:
			cmp al, 'p'
			jne .add

			bppop ax

			call hexprint16

			; Newline
			mov al, 10
			call putchar

		.add:
			cmp al, '+'
			jne .sub

			bppop bx
			bppop ax

			add ax, bx

			bppush ax

			jmp .mainloop

		.sub:
			cmp al, '-'
			jne .mul

			bppop bx
			bppop ax

			sub ax, bx

			bppush ax

			jmp .mainloop

		.mul:
			cmp al, '*'
			jne .div

			bppop bx
			bppop ax

			mul bx

			bppush ax
			xor dx, dx ; Zero dx for number input

			jmp .mainloop

		.div:
			cmp al, '/'
			jne .mainloop

			bppop bx
			bppop ax

			xor dx, dx
			div bx

			bppush ax
			xor dx, dx ; Zero dx for number input

			jmp .mainloop

end:
	mov si, endmsg
	call puts

	pop es
	popa
	ret

endmsg: db 'end', 10, 0

%include "hexprint.inc"
