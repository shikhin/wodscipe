org 0x7C00

start:
	jmp 0x0:.segsetup
	
	; Jump table
	jmp word putchar
	jmp word puts
	
	.segsetup:
		xor bx, bx
		
		mov ss, bx
		mov sp, start
		
		mov ds, bx
		mov es, bx
	
	cld

hang:
	hlt
	jmp hang

%include "io.asm"
%include "disk.asm"
%include "editor.asm"

times 510-($-$$) db 0
dw 0xAA55

interpreter:
