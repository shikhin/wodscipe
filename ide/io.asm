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
