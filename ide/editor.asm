editor:
	.loadsource:
		mov ax, 2
		mov bx, 0x8000
		xor di, di
		call rwsector

		mov bp, 0x8002 ; Current start-of-line

		jmp rw_source

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
			.cmdinsert:
				; hack: cx & di already set, by above
				call getline
				push di

				mov cx, [0x8000]
				add cx, 0x8002
				sub cx, bp

				mov si, bp
				add si, cx
				mov di, si
				add di, ax
				inc di
				
				inc cx

				std
				rep movsb
				cld

				pop si
				mov di, bp
				mov cx, ax

				rep movsb

				inc ax
				add [0x8000], ax

				mov al, 10
				stosb

				xor al, al

		.append:
			cmp al, 'a'
			jne .delete
			; Append
			.cmdappend:
				call next_newline
				mov bp, si
				jmp .cmdinsert

		.delete:
			cmp al, 'd'
			jne .print
			; Delete
			.cmddelete:
				call next_newline

				mov bx, 0x8000
				sub [bx], si
				add [bx], bp

				call is_bufend
				mov cx, bx
				sub cx, bp

				mov di, bp
				rep movsb

				mov si, bp
				call is_bufend
				ja .deleted

				call prev_newline
				mov bp, si

				.deleted:
					xor al, al

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
			.cmdwrite:
				; How many sectors to write.
				; (len + 2 + 511)/512 -> (len + 1)/512 + 1
				mov bx, 0x8000
				mov ax, 2
				mov di, 1 << 8
				jmp rw_source

		.run:
			cmp al, 'r'
			jne .next
			; Run
			.cmdrun:
				; Hack to make interpreter return directly to mainloop
				call interpreter
				xor al, al

		.next:
			cmp al, '+'
			jne .previous
			; Next
			.cmdnext:
				call next_newline
				call is_bufend
				jz .error

				mov bp, si
				jmp .cmdprint

		.previous:
			cmp al, '-'
			jne .nomatch
			; Previous
			.cmdprevious:
				cmp bp, 0x8002
				je .error

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
;	DI -> for rwsector.
;	AX, BX -> initialized.
rw_source:
	mov cx, [bx]
	inc cx
	shr cx, 9
	inc cx

	.writeloop:
		call rwsector

		inc ax
		add bx, 0x200
		loop .writeloop

	jmp editor.mainloop

; IN:
;	SI -> pointer
; OUT:
; 	ZF -> 1, end of buffer, else not.
; BX trashed.
is_bufend:
	mov bx, [0x8000]
	add bx, 0x8002
	cmp bx, si
	ret

; IN:
;	BP -> buffer
;   DX -> is_buf{end,start}
;   Direction flag clear for next new line, set for previous new line.
; OUT:
;	SI -> next/previous line, or end/start of buffer
prev_newline:
	lea si, [bp - 1]
	cmp si, 0x8003

	jae .find_prevline
	mov si, 0x8003

	.find_prevline:
		.loop:
			dec si
			; If reached start/end of buffer
			cmp si, 0x8002
			jbe .ret

			cmp [si], byte 10
			jne .loop

		.end:
			inc si
		.ret:
			ret

; IN:
;	BP -> buffer
;   DX -> is_buf{end,start}
;   Direction flag clear for next new line, set for previous new line.
; OUT:
;	SI -> next/previous line, or end/start of buffer
next_newline:
	push ax

	mov si, bp
	.loop:
		; If reached start/end of buffer
		call is_bufend
		jbe .end

		lodsb
		cmp al, 10
		jne .loop

	.end:
		pop ax

	.ret:
		ret
