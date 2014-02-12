org 0x7C00
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
		mov sp, start
		
		mov ds, bx
		mov es, bx
	
	cld
	
	mov [BOOTDEV], dl

	.loadinterpreter:
		mov bx, 1
		mov bp, interpreter
		xor di, di
		call rwsector
	
	jmp editor

panic:
	call putchar
hang:
	hlt
	jmp hang

%include "io.asm"
%include "disk.asm"
%include "editor.asm"

times 510-($-$$) db 0
dw 0xAA55

interpreter:
