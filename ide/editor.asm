; The editor.
; IN:
;	BX -> 0x8000.
;	AX -> 2
;	DI -> 0
editor:
	.loadsource:
		lea bp, [bx + 2] ; Current start-of-line
		mov dx, bp
		add dx, [bx]

	.rw_source:
		push bx
		.writeloop:
			call rwsector

			inc ax
			add bx, 0x200
			cmp bx, dx
			jb .writeloop

		pop bx

	.mainloop:
		; Input buffer.
		mov di, 0x504
		; 80 characters (most probably width of current mode's line, mode 03)
		mov cx, 0x50
		call getline

		cmp al, 1
		jb .cmdnext	; 0.
		jne .error	; 1 char commands.

		.checkcmd:
			mov al, [di]

		.insert:
			cmp al, 'i'
			jne .append
			; Insert
			.cmdinsert:
				; cx & di already set above
				call getline
				push di

				; Get bytes following bp = last "address" - bp.
				mov cx, dx
				sub cx, bp

				; Copy from BP to (BP + AX + 1), but reversed (as overlap).
				mov si, bp
				add si, cx
				mov di, si
				add di, ax
				inc di

				inc cx

				std
				rep movsb
				cld

				; Copy from input buffer to BP, the new line.
				pop si
				mov di, bp
				mov cx, ax

				rep movsb

				; Update file length.
				inc ax
				add [bx], ax
				add dx, ax

				mov al, 10
				stosb

				xor al, al

		.append:
			cmp al, 'a'
			jne .delete
			; Append
			.cmdappend:
				; Go to next line, and insert before that.
				call next_newline
				mov bp, si
				jmp .cmdinsert

		.delete:
			cmp al, 'd'
			jne .print
			; Delete
			.cmddelete:
				; Find next newline.
				call next_newline

				; Get number of bytes from next line to end.
				mov cx, dx
				sub cx, si

				; Remove size of current line from [bx].
				sub [bx], si
				add [bx], bp
				sub dx, si
				add dx, bp

				mov di, bp
				rep movsb

				; If at end of buffer, go to line before.
				mov si, bp
				cmp dx, si
				ja .deleted

				call prev_newline
				.deleted:
					xor al, al

		.print:
			cmp al, 'p'
			jne .write
			; Print
			.cmdprint:
				; Get next line.
				call next_newline

				; Put a null-terminator at beginning of next line.
				xor al, al
				xchg [si], al

				; Print.
				xchg si, bp
				call puts

				; Restore character.
				xchg si, bp
				xchg [si], al

		.write:
			cmp al, 'w'
			jne .run
			; Write
			.cmdwrite:
				mov ax, 2
				mov di, 1 << 8
				jmp .rw_source

		.run:
			cmp al, 'r'
			jne .next
			; Run
			.cmdrun:
				call interpreter
				xor al, al

		.next:
			cmp al, '+'
			jne .last
			; Next
			.cmdnext:
				call next_newline
				cmp dx, si
				jz .error

				mov bp, si
				jmp .cmdprint

		.last:
			cmp al, '$'
			jne .previous
			; Last
			.cmdlast:
				; Find the previous line from EOF.
				mov bp, dx
				jmp .cmdprevious

		.previous:
			cmp al, '-'
			jne .first
			; Previous
			.cmdprevious:
				cmp bp, 0x8002
				je .error

				call prev_newline
				jmp .cmdprint

		.first:
			cmp al, '1'
			jne .list
			; First
			.cmdfirst:
				lea bp, [bx + 2]
				jmp .cmdprint

		.list:
			cmp al, 'l'
			jne .nomatch
			; List
			.cmdlist:
				lea si, [bx + 2]
				mov cx, [bx]
				jcxz .listed

				.loop:
					lodsb
					call putchar
					loop .loop

				.listed:
					xor al, al

		.nomatch:
			test al, al
			jz .mainloop

	.error:
		mov si, .errormsg
		call puts
		jmp .mainloop

	.errormsg: db '?', 10, 0

; Find previous line.
; IN:
;	BP -> buffer
; OUT:
;	BP -> previous line, or start of buffer
prev_newline:
	dec bp
	cmp bp, 0x8003

	jae .find_prevline
	mov bp, 0x8003

	.find_prevline:
		.loop:
			dec bp
			; If reached start/end of buffer
			cmp bp, 0x8002
			jbe .ret

			cmp [bp], byte 10
			jne .loop

		.end:
			inc bp
		.ret:
			ret

; Find next line.
; IN:
;	BP -> buffer
; OUT:
;	SI -> next/previous line, or end/start of buffer
;	DX -> bx + 2 + [bx]
next_newline:
	mov si, bp
	.loop:
		; If reached start/end of buffer
		cmp dx, si
		jbe .end

		lodsb
		cmp al, 10
		jne .loop

	.end:
		ret
