editor:
	.loadsource:
		mov bx, 2
		mov bp, 0x8000
		mov di, 0
		call rwsector
		
		; How many sectors still to read
		; It works and I can explain it if need be --nortti
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
	
	; Temporary testing stuff, please ignore.
	
	mov cx, [0x8000]
	mov si, 0x8002
	.printloop:
		lodsb
		call putchar
		loop .printloop

	.getlinetest:
		mov di, 0x504
		mov cx, 0x10
		call getline
		
		mov si, di
		call puts
		
		jmp .getlinetest
