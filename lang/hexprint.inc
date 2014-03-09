; IN:
;	AL -> byte to output
hexprint8:
	pusha
	
	mov ah, al
	shr al, 4
	call hexprint4
	
	mov al, ah
	and al, 0xF
	call hexprint4
	
	popa
	ret

; IN:
;	AL -> nibble to output
hexprint4:
	pusha
	
	cmp al, 9
	ja .rangeAF
	
	.range09:
		add al, '0'
		jmp .printchar
	
	.rangeAF:
		add al, 'A'-10
	
	.printchar:
		call putchar
		
	.end:
		popa
		ret
