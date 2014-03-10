editor:
	.loadsource:
		lea bp, [bx + 2] ; Current start-of-line

	.rw_source:
		mov cx, [bx]
		inc cx
		shr cx, 9
		inc cx

		push bx
		.writeloop:
			call rwsector

			inc ax
			add bx, 0x200
			loop .writeloop
		pop bx

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

				lea cx, [bx + 2]
				add cx, [bx]
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
				add [bx], ax

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

				sub [bx], si
				add [bx], bp

				lea cx, [bx + 2]
				add cx, [bx]
				sub cx, bp

				mov di, bp
				rep movsb

				mov si, bp
				call is_bufend
				ja .deleted

				call prev_newline
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
				mov ax, 2
				mov di, 1 << 8
				jmp .rw_source

		.run:
			cmp al, 'r'
			jne .next
			; Run
			.cmdrun:
				; Hack to make interpreter return directly to mainloop
				pusha
				call interpreter
				popa
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
				lea bp, [bx + 2]
				add bp, [bx]
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
				call puts
				xor al, al

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
; DX trashed.
is_bufend:
	lea dx, [bx + 2]
	add dx, [bx]
	cmp dx, si
	ret

; IN:
;	BP -> buffer
;   DX -> is_buf{end,start}
;   Direction flag clear for next new line, set for previous new line.
; OUT:
;	SI -> next/previous line, or end/start of buffer
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
