editor:
	.loadsource:
		mov bx, 2
		mov bp, 0x8000
		mov di, 0
		call rwsector
		
		; How many sectors still to read
		; (len+2+511-512)/512 -> (len+1)/512
		mov cx, [0x8000]
		inc cx
		shr cx, 9
		
		.loadloop:
			jcxz .endloop

			inc bx
			add bp, 0x200
			call rwsector
			
			dec cx
			jmp .loadloop
		.endloop:
	
	mov bp, 0x8002 ; Current start-of-line
	
	.mainloop:
		mov di, 0x504 ; Input buffer
		mov cx, 0x50 ; 80 char, the width of textmode line
		call getline
		
		cmp al, 0 ; Compare just al, len will fit in one byte
		je .cmdnext
		
		cmp al, 1 ; All commands are 1 char
		je .checkcmd
		
		; Gotoline
		
		jmp .mainloop
		
		.checkcmd:
			mov al, [0x504]
			
			cmp al, 'i'
			jne .skip1
			; Insert
		.skip1:
			cmp al, 'a'
			jne .skip2
			; Append
		.skip2:
			cmp al, 'd'
			jne .skip3
			; Delete
		.skip3:
			cmp al, 'c'
			jne .skip4
			; Change
		.skip4:
			cmp al, 'p'
			jne .skip5
			; Print
			.cmdprint:
				call nextnewline
				
				mov [si], byte 0
				
				xchg si, bp
				call puts
				
				xchg si, bp
				mov [si], byte 10
				
				jmp .mainloop
		.skip5:
			cmp al, 'w'
			jne .skip6
			; Write
		.skip6:
			cmp al, 'r'
			jne .skip7
			; Run
			.cmdrun:
				; Put the start of scratch space into si, align to 512B to prevent saving of junk to disk
				mov si, bp
				add si, [0x8000]
				add si, 0x1FF
				and si, 0xFE00
				
				; Hack to make interpreter return directly to mainloop
				pusha
				call interpreter
				popa
				
				jmp .mainloop
		.skip7:
			cmp al, '+'
			jne .skip8
			; Next
			.cmdnext:
		.skip8:
			cmp al, '-'
			jne .isdigit
		
		.isdigit:
			cmp al, '0'
			jb .mainloop
			cmp al, '9'
			ja .mainloop
			; Gotoline
			
			jmp .mainloop
	.error:
		mov si, .errormsg
		call puts
		jmp .mainloop
	.errormsg: db '?', 0

; IN: si=pointer
; OUT: cf=0:newline 1:end of buf
iseob:
	push bx
	
	clc
	
	mov bx, [0x8000]
	add bx, 0x8002
	cmp bx, si
	jne .end
	
	.true:
		stc
	.end:
		pop bx
		
		ret


; IN: bp=buffer
; OUT: si=either newline or end of buffer
nextnewline:
	push ax
	
	clc
	mov si, bp
	
	.loop:
		; If reached end of buffer
		call iseob
		je .end
		
		lodsb
		cmp al, 10
		je .end
		
		jmp .loop
	.end:
		pop ax
		
		ret
