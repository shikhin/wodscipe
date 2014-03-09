ORG 0x7C00
CPU 386

%define BOOTDEV  0x502

start:
	jmp 0x0:.segsetup

	; Jump table
	jmp word putchar
	jmp word puts
	jmp word getch
	jmp word getline

	.segsetup:
		xor bx, bx

		mov ss, bx
		mov esp, start

		mov ds, bx
		mov es, bx

	cld

	mov [BOOTDEV], dl

	.loadinterpreter:
		mov ax, 1
		mov bx, interpreter
		xor di, di
		call rwsector

; The editor continues.
%include "editor.asm"

panic:
	; Get in the character.
	mov al, '@'
	call putchar
hang:
	hlt
	jmp hang

%include "io.asm"
%include "disk.asm"

times 510-($-$$) db 0
dw 0xAA55

interpreter:
