ORG 0x7C00
CPU 386

%define BOOTDEV  0x502

; Wodscipe IDE entry point.
; IN:
;	CS:IP -> 0x7C00.
;	DL -> boot drive identifier for int 0x13 calls.
; OUT:
;	Fairies and unicorns.
start:
	jmp 0x0:segsetup

	; Jump table
	jmp putchar
	jmp puts
	jmp getch
	jmp getline

%include "io.asm"
%include "disk.asm"

	segsetup:
		xor ax, ax

		mov ss, ax
		mov sp, start

		mov ds, ax
		mov es, ax

	cld

	mov [BOOTDEV], dl

	; Load the interpreter and the first sector of source code.
	mov cx, 2
	xor di, di
	mov bx, interpreter - 0x200
	.load:
		add bx, 0x200
		inc ax
		call rwsector
		loop .load

; The editor continues.
%include "editor.asm"

times 510-($-$$) db 0
dw 0xAA55

interpreter:
