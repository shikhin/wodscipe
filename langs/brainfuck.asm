%include "wodscipe.inc"

; Uncomment following line to enable NorttiSoft singlestepping BF debugger deluxe
; %define enable_debugger

%macro debugger 0
	; Current IP
	mov ax, si
	xchg al, ah
	call hexprint8
	xchg al, ah
	call hexprint8
	mov al, ' '
	call putchar
	
	; Current command
	mov al, [si]
	call putchar
	mov al, ' '
	call putchar
	
	; Current tape pointer
	mov ax, bp
	xchg al, ah
	call hexprint8
	xchg al, ah
	call hexprint8
	mov al, ' '
	call putchar
	
	; Current tabe symbol
	mov al, [es:bp]
	call hexprint8
	mov al, 10
	call putchar
	
	; Wait for keypress
	call getch
%endmacro

start:
	push bp
	push es
	
	; Tape & tape pointer
	mov ax, 0x1000
	mov es, ax
	mov bp, 0
	
	; Zero tape
	xor di, di
	mov cx, 0xFFFF
	xor al, al
	rep stosb
	
	; Source
	mov si, 0x8002
	mov di, [0x8000]
	add di, 0x8002
	
	call interpret
	
	pop es
	pop bp
	ret

interpret:
	cmp si, di
	je .end
	
	%ifdef enable_debugger
		debugger
	%endif
	
	lodsb
	
	.inc:
		cmp al, '+'
		jne .dec
		
		inc byte [es:bp]
		
		jmp interpret
	.dec:
		cmp al, '-'
		jne .next
		
		dec byte [es:bp]
		
		jmp interpret
	.next:
		cmp al, '>'
		jne .prev
		
		inc bp
		
		jmp interpret
	.prev:
		cmp al, '<'
		jne .putchar
		
		dec bp
		
		jmp interpret
	.putchar:
		cmp al, '.'
		jne .getchar
		
		mov al, [es:bp]
		call putchar
		
		jmp interpret
	.getchar:
		cmp al, ','
		jne .while
		
		call getch
		call putchar
		cmp al, 04
		jne .not_eof
		
		.eof:
			xor al, al
		.not_eof:
			mov [es:bp], al
		
		jmp interpret
	.while:
		cmp al, '['
		jne .wend
		
		; Handle loop nesting by recursion inside a loop
		.loop:
			cmp byte [es:bp], 0
			je .skip
			
			push si
			call interpret
			pop si
			
			jmp .loop
		.skip:
			; Skip after the loop(s). Needed because si is returned to same point where it left
			mov cx, 1
			
			.skiploop:
				jcxz .skipend
				
				lodsb
				
				cmp al, '['
				je .deeper
				cmp al, ']'
				je .shallower
				
				jmp .skiploop
				
				.deeper:
					inc cx
					jmp .skiploop
				.shallower:
					dec cx
					jmp .skiploop
			.skipend:
				jmp interpret
	.wend:
		cmp al, ']'
		jne interpret
		
		; Fall trough
	.end:
		ret

%ifdef enable_debugger
	%include "hexprint.inc"
%endif
