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
;	BX -> N.
; OUT:
;	Carry flag set if unequal.
memcmp:
	pusha

	mov cx, bx

	.loop:
		jcxz .equal
		lodsb

		cmp al, [di]
		jne .unequal

		inc di
		loop .loop

	.equal:
		clc
	.ret:
		popa
		ret

	.unequal:
		stc
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

	dec cx
	add di, cx
	add si, cx
	inc cx

	.forward:
		rep movsb

	cld
	popa
	ret

; Substitute one string from another in source.
; IN:
;	DI -> string to replace.
;	BX -> length of string.
;	AX -> string to replace with.
;	DX -> length of string to replace with.
; OUT:
;	Carry flag set if not found.
substitute:
	pusha

	; If total length < length of string to find, then fail.
	cmp cx, bx
	jb .not_found

	; Else, note that it's futile to search last BX bytes.
	sub cx, bx
	inc cx

	; Start searching from beginning, CX times.
	xor si, si
	.search:
		; If found the string, replace it.
		call memcmp
		jnc .replace

		inc si
		loop .search

	; We didn't find the string.
	.not_found:
		stc
		popa
		ret

	.replace:
		pusha
		mov di, si
		add si, bx
		add di, dx
		call memmove
		popa

		mov di, si
		mov si, ax
		mov cx, dx
		rep movsb

	.found:
		clc
		popa

		sub cx, bx
		add cx, dx
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

		cmp al, '\'
		jne .elem

		call remove_char
		cmp si, cx
		je .no_more_slashes

		lodsb
	.elem:
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

puts_debug:
	pusha

	.putc:
		lodsb
		call putchar
		loop .putc

	popa
	ret

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

		mov di, 0x8000

		call get_next_slash
		jc .end

		; DI -> string to replace, BX -> length of string.
		mov ax, di
		mov dx, bx

		add di, dx
		; AX -> string to replace, DX -> length of string.
		call get_next_slash
		jc .end
		xchg di, ax
		xchg bx, dx

		call remove_char
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
