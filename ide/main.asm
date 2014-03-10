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
		xor ax, ax

		mov ss, ax
		mov esp, start

		mov ds, ax
		mov es, ax

	cld

	mov [BOOTDEV], dl

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

%include "io.asm"
%include "disk.asm"

;times 510-($-$$) db 0
dw 0xAA55

interpreter:
