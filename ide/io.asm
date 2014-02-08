; IN: al=char to output
putchar:
	pusha
	
	mov ah, 0xE
	int 0x10
	
	cmp al, 10
	jne .end
	
	mov al, 13
	int 0x10
	
	.end:
		popa
		ret

; IN: si=null-terminated string
puts:
	pusha
	
	.loop:
		lodsb
		cmp al, 0
		je .end
		
		call putchar
		
		jmp .loop
	
	.end:
		popa
		ret

; OUT: al=inputted char
getch:
	push bx
	push ax
	
	xor ax, ax
	int 0x16
	
	mov bx, ax
	pop ax
	mov al, bl
	pop bx
	
	cmp al, 13
	jne .end
	
	.newline:
		mov al, 10
	.end:
		ret
