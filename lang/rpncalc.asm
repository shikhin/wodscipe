%include "wodscipe.inc"

main:
	mov bp, si
	mov si, 0x8002
	mov cx, [0x8000]
	add cx, 0x8002
	
	.mainloop:
		cmp si, cx
		je end
		
		lodsb
		call putchar
		
		jmp .mainloop
end:
	ret
	
times 512-($-$$) db 0
