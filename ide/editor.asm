editor:
	.loadsource:
		mov ax, 2
		mov bx, 0x8000
		xor di, di
		call rwsector

		; How many sectors still to read
		; (len + 2 + 511)/512 -> (len + 1)/512 + 1
		mov cx, [bx]
		inc cx
		shr cx, 9
		inc cx

		.loadloop:
			call rwsector

			inc ax
			add bx, 0x200
			loop .loadloop

	mov bp, 0x8002 ; Current start-of-line

	.mainloop:
		mov di, 0x504 ; Input buffer
		mov cx, 0x50 ; 80 char, the width of textmode line
		call getline

		cmp al, 0 ; Compare just al, len will fit in one byte
		je .cmdnext

		cmp al, 1 ; All commands are 1 char
		jne .error

		.checkcmd:
			mov al, [di]

		.insert:
			cmp al, 'i'
			jne .append
			; Insert

		.append:
			cmp al, 'a'
			jne .delete
			; Append

		.delete:
			cmp al, 'd'
			jne .change
			; Delete

		.change:
			cmp al, 'c'
			jne .print
			; Change

		.print:
			cmp al, 'p'
			jne .write
			; Print
			.cmdprint:
				call next_newline

				xor al, al
				xchg [si], al

				xchg si, bp
				call puts

				xchg si, bp
				xchg [si], al

		.write:
			cmp al, 'w'
			jne .run
			; Write

		.run:
			cmp al, 'r'
			jne .next
			; Run
			.cmdrun:
				; Put the start of scratch space into si, align to 512B to prevent saving of junk to disk
				mov si, 0x8002
				add si, [0x8000]
				add si, 0x1FF
				and si, 0xFE00

				; Hack to make interpreter return directly to mainloop
				call interpreter
				xor al, al

		.next:
			cmp al, '+'
			jne .last
			; Next
			.cmdnext:
				call next_newline
				call is_bufend
				jz .error

				mov bp, si
				jmp .cmdprint

		.last:
			cmp al, '$'
			jne .previous
			; Last
			.cmdlast:
				call next_newline
				call is_bufend
				jz .cmdprint

				mov bp, si
				jmp .cmdlast

		.previous:
			cmp al, '-'
			jne .nomatch
			; Previous
			.cmdprevious:
				cmp bp, 0x8002
				je .error

				sub bp, 2
				call prev_newline
				mov bp, si
				jmp .cmdprint

		.nomatch:
			test al, al
			jz .mainloop

	.error:
		mov si, .errormsg
		call puts
		jmp .mainloop

	.errormsg: db '?', 10, 0

; IN:
;	SI -> pointer
; OUT:
; 	ZF -> 1, end of buffer, else not.
is_bufend:
	push bx
	mov bx, [0x8000]
	add bx, 0x8002
	cmp bx, si
	pop bx
	ret

; IN:
;	SI -> pointer
; OUT:
; 	ZF -> 1, start of buffer, else not.
is_bufstart:
	cmp si, 0x8002
	ret

; IN:
;	BP -> buffer
prev_newline:
	mov dx, is_bufstart
	std
	jmp find_newline

; IN:
;	BP -> buffer
next_newline:
	mov dx, is_bufend
; IN:
;	BP -> buffer
;   DX -> is_buf{end,start}
;   Direction flag clear for next new line, set for previous new line.
; OUT:
;	SI -> next/previous line, or end/start of buffer
find_newline:
	push ax

	mov si, bp
	.loop:
		; If reached start/end of buffer
		call dx
		jbe .end

		lodsb
		cmp al, 10
		jne .loop

	.end:
		cld

		pop ax
		ret
