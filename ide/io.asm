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

; IN: DI=buffer   CX=length of buffer
; OUT: AX=chars read
; NOTE: do _not_ pass 0-byte buffers
getline:
	push bx
	push di
	push si
	
	dec cx
	mov bx, 0
	.readloop:
		
		call getch
		
		cmp al, 8
		je .delete
		
		cmp al, 10
		je .end
		
		cmp bx, cx
		je .readloop
		
		call putchar
		stosb
		inc bx
		
		jmp .readloop
		
		.delete:
			cmp bx, 0
			je .readloop
			
			mov si, .del_string
			call puts
			
			dec bx
			dec di
			
			jmp .readloop
		.del_string: db 8, ' ', 8, 0
		
		.end:
			call putchar
			
			xor al, al
			stosb
			
			mov bx, ax
			inc cx
			
			pop si
			pop di
			pop bx
			ret
