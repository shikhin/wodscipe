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
				call nextnewline

				mov [si], byte 0

				xchg si, bp
				call puts

				xchg si, bp
				mov [si], byte 10

				xor al, al

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
			jne .previous
			; Next
			.cmdnext:

		.previous:
			cmp al, '-'
			jne .nomatch
			; Previous

		.nomatch:
			test al, al
			jz .mainloop

	.error:
		mov si, .errormsg
		call puts
		jmp .mainloop

	.errormsg: db '?', 10, 0

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
