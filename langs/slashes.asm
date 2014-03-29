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

	; SI is cleared out, CX contains length.
	xor si, si
	mov cx, [bx]

	; DS is also 0x1000
	mov ds, ax

	call interpret

	pop ds
	pop es
	popa
	xor al, al
	ret

; Removes the first character.
; IN:
;	SI -> 1
;	CX -> end of source.
; OUT:
;	SI -> 0
;	CX -> CX - 1
remove_char:
	pusha

	xor di, di
	dec cx
	rep movsb

	popa

	; Update SI and CX.
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

	; Copy backwards.
	dec cx
	add di, cx
	add si, cx
	inc cx

	; Straight-forward copy.
	.forward:
		rep movsb

	cld
	popa
	ret

; Substitute one string from another in source, as per governing dynamics.
; IN:
;	DI -> string to replace.
;	BX -> length of string.
;	AX -> string to replace with.
;	DX -> length of string to replace with.
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
		popa
		ret

	.replace:
		; Make space for the new pattern.
		pusha
		mov di, si
		add si, bx
		add di, dx
		call memmove
		popa

		; Replace it in there.
		mov di, si
		mov si, ax
		mov cx, dx
		rep movsb

	; If found, we need to try again.
	.found:
		popa
		sub cx, bx
		add cx, dx
		jmp substitute

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

; Interpreter.
interpret:
	test cx, cx
	jz .end

	lodsb

	.back_slash:
		cmp al, '\'
		jne .forward_slash

		call remove_char
		jcxz .end

		lodsb
		jmp .print_char

	.forward_slash:
		cmp al, '/'
		jne .print_char

		; Free space from pattern+replacement buffer.
		mov di, 0xC000

		call get_next_slash
		jc .end

		; Save DI, BX in AX, DX.
		mov ax, di
		mov dx, bx

		; Save replacement string at DI + BX.
		add di, bx
		call get_next_slash
		jc .end

		; Retain the order.
		xchg di, ax
		xchg bx, dx

		call remove_char
		call substitute

		jmp interpret

	.print_char:
		call putchar
		call remove_char
		jmp interpret

	.end:
		ret
