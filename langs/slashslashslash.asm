; Realm of slash-slash-slash.
; Contains sloppy-sloppy-sloppy code.
; You were warned.

%include "wodscipe.inc"
org 0x7E00

start:
	pusha
	push es
	push ds

	; Copy of source code in second segment.
	mov ax, 0x1000
	mov es, ax

	lea si, [bx + 2]
	xor di, di
	mov cx, [bx]
	rep movsb

	; SI points to source, CX contains length (or end).
	xor si, si
	mov cx, [bx]

	; DS is also 0x1000
	mov ds, ax

	call interpret

	pop ds
	pop es
	popa
	ret

; Removes the character before SI.
; IN:
;	SI -> character from which to move one behind.
;	CX -> end of source.
; OUT:
;	SI -> SI - 1
;	CX -> CX - 1
remove_char:
	pusha

	lea di, [si - 1]
	sub cx, si
	rep movsb

	popa
	dec si
	dec cx
	ret

; Compares N bytes.
; IN:
;	SI, DI -> input.
;	AX -> N.
; OUT:
;	Carry flag set if unequal.
memcmp:
	pusha

	mov cx, ax

	.loop:
		jcxz .equal
		lodsb

		cmp al, [di]
		jne .unequal

		inc di
		loop .loop

	.unequal:
		stc
	.ret:
		popa
		ret

	.equal:
		clc
		jmp .ret

; IN:
;	SI -> source.
;	DI -> destination.
;	CX -> number of bytes.
memmove:
	pusha

	cmp di, si
	jbe .forward

	std

	add di, cx
	add si, cx

	.forward:
		rep movsb

	cld
	popa
	ret

; Substitute one string from another in source.
; IN:
;	DI -> string to replace.
;	AX -> length of string.
;	BX -> string to replace with.
;	DX -> length of string to replace with.
; OUT:
;	Carry flag set if not found.
substitute:
	pusha

	cmp cx, ax
	jb .not_found

	sub cx, ax
	inc cx

	xor si, si
	.search:
		call memcmp
		jnc .replace

		inc si
		loop .search

	.not_found:
		xchg bx, bx
		stc
		jmp .ret

	.replace:
		pusha
		mov di, si
		add si, ax
		add di, bx
		popa

		mov di, si
		mov si, bx
		mov cx, dx
		rep movsb

	.found:
		clc

	.ret:
		popa
		ret

; Finds the next slash.
; IN:
;	SI -> pointing at current location.
; OUT:
;	DI -> string till next slash.
;	BX -> length of string.
;	Carry set if slash not found.
get_next_slash:
	push ax

	xor bx, bx

	.loop:
		call remove_char
		cmp si, cx
		je .no_more_slashes

		lodsb
		cmp al, '/'
		je .finished

		mov [di + bx], al
		inc bx
		jmp .loop 

	.no_more_slashes:
		stc
	.ret:
		pop ax
		ret

	.finished:
		clc
		jmp .ret

; Interpreter.
interpret:
	cmp si, cx
	je .end

	lodsb

	.back_slash:
		cmp al, '\'
		jne .forward_slash

		call remove_char
		cmp si, cx
		je .end

		lodsb
		jmp .print_char

	.forward_slash:
		cmp al, '/'
		jne .print_char

		call get_next_slash
		jc .end
		; DI -> string to replace, BX -> length of string.
		xchg di, ax
		xchg bx, dx
		; AX -> string to replace, DX -> length of string.
		call get_next_slash
		jc .end
		; DI -> string to replace with, BX -> length of string to replace with.
		xchg bx, di ; BX = correct, DI = length of string to replace with.
		xchg di, dx ; DX = correct, DI = length of string.
		xchg di, ax

		.loop:
			call substitute
			jnc .loop

		xor si, si
		jmp interpret

	.print_char:
		call putchar
		call remove_char
		xor si, si

	jmp interpret

	; Fall through.
	.end:
		ret
